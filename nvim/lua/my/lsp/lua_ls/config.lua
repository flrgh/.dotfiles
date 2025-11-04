local storage = require("my.storage")
local fs = require("my.utils.fs")
local luamod = require("my.utils.luamod")
local clear = require("table.clear")
local WS = require("my.workspace")
local plugin = require("my.utils.plugin")
local proto = require("vim.lsp.protocol")
local const = require("my.lsp.lua_ls.constants")
local DEFAULTS = require("my.lsp.lua_ls.defaults")
local Set = require("my.utils.set")

local lsp = vim.lsp
local endswith = vim.endswith
local insert = table.insert
local deepcopy = vim.deepcopy
local deep_equal = vim.deep_equal

---@type string[]
local LUA_PATH_ENTRIES = luamod.LUA_PATH_ENTRIES

local SRC_TYPE_DEFS = const.SRC_TYPE_DEFS
local SRC_RUNTIME_PATH = const.SRC_RUNTIME_PATH
local SRC_WS_LIBRARY = const.SRC_WS_LIBRARY
local SRC_PLUGIN = const.SRC_PLUGIN
local SRC_WORKSPACE_ROOT = const.SRC_WORKSPACE_ROOT


local EMPTY = {}

local workspaceDidChangeConfiguration = proto.Methods.workspace_didChangeConfiguration

storage.global.lua_lsp = storage.global.lua_lsp or {}
local STATES = storage.global.lua_lsp

local NAME = const.NAME

---@param paths my.Set
---@param dir string
local function add_lua_path(paths, dir)
  if not dir or dir == "" then return end

  paths:add(dir .. "/?.lua")
  paths:add(dir .. "/?/init.lua")
end



---@class my.lua_ls.Config
---
---@field id integer
---@field resolver my.lua.resolver
---@field config my.lsp.config.Lua
---@field meta { [string]: boolean }
---@field dirty boolean
---@field workspace_library my.Set
---@field runtime_path my.Set
---@field ignore_dir my.Set
---@field addons my.Set
---@field definitions my.Set
---@field modules my.Set
local Config = {}
local Config_mt = { __index = Config }

---@param id integer|"default"
---@param config? my.lsp.config.Lua
---@return my.lua_ls.Config
function Config.new(id, config)
  local self = setmetatable({
    id = id,
    client = nil,
    config = deepcopy(config),
    resolver = luamod.resolver.new(),
    meta = {},
    dirty = false,
    workspace_library = Set.new(),
    runtime_path = Set.from({ "?.lua", "?/init.lua" }),
    ignore_dir = Set.new(),
    addons = Set.new(),
    definitions = Set.new(),
    modules = Set.new(),
  }, Config_mt)


  local Lua = self.config.settings.Lua

  for _, path in ipairs(Lua.runtime.path or EMPTY) do
    self:add_runtime_path(path)
  end
  Lua.runtime.path = self.runtime_path.items

  for _, lib in ipairs(Lua.workspace.library or EMPTY) do
    self:add_workspace_library(lib)
  end
  Lua.workspace.library = self.workspace_library.items

  for _, ign in ipairs(Lua.workspace.ignoreDir or EMPTY) do
    self:add_ignore(ign)
  end
  Lua.workspace.ignoreDir = self.ignore_dir.items

  for _, addon in ipairs(Lua.workspace.userThirdParty or EMPTY) do
    self.addons:add(addon)
  end
  Lua.workspace.userThirdParty = self.addons.items
  if self.addons.len > 0 then
    Lua.workspace.checkThirdParty = const.ApplyInMemory
  else
    Lua.workspace.checkThirdParty = const.Disable
  end

  local resolver = self.resolver
  resolver:add_lua_package_path()
  resolver:add_env_lua_path()

  for _, path in ipairs(resolver.paths) do
    self:add_runtime_dir(path.dir)
  end

  for _, path in ipairs(self.runtime_path.items) do
    resolver:add_path(path, { source = SRC_RUNTIME_PATH })
  end

  for _, lib in ipairs(self.workspace_library.items) do
    resolver:add_dir(lib, { source = SRC_WS_LIBRARY })
  end

  STATES[id] = self

  return self
end


---@param id _vim.lsp.client.id
---@return my.lua_ls.Config?
function Config.get(id)
  assert(type(id) == "number")

  return STATES[id]
end


---@param id _vim.lsp.client.id
---@return my.lua_ls.Config
function Config.get_or_create(id)
  assert(type(id) == "number")

  if STATES[id] then
    return STATES[id]
  end

  local config = (STATES[0] and STATES[0].config)
    or (STATES.default and STATES.default.config)
    or DEFAULTS

  return Config.new(id, config)
end


---@param search string
---@param tree? my.lua.resolver.path
---@return my.lua_ls.Config
function Config:add_runtime_path(search, tree)
  self.resolver:add_path(search, { source = SRC_RUNTIME_PATH })
  if self.runtime_path:add(search) then
    self.dirty = true
    lsp.log.info({
      event = "insert Lua.runtime.path",
      path = search,
      meta = tree and tree.meta,
    })
  end

  return self
end


---@param dir string
---@return my.lua_ls.Config
function Config:add_runtime_dir(dir)
  return self:add_runtime_path(dir .. "/?.lua")
    :add_runtime_path(dir .. "/?/init.lua")
end


---@param path string
---@param tree? my.lua.resolver.path
---@return my.lua_ls.Config
function Config:add_workspace_library(path, tree)
  local ft, lt = fs.type(path)

  if ft == "file" or lt == "file" then
    for parent in fs.iter_parents(path) do
      if self.workspace_library:contains(parent) then
        return self
      end
    end

  else
    self:add_runtime_dir(path)
  end

  if self.workspace_library:add(path) then
    self.dirty = true
    lsp.log.info({
      event = "insert Lua.workspace.library",
      path = path,
      meta = tree and tree.meta,
    })
  end

  return self
end


---@param lib string
---@return my.lua_ls.Config
function Config:add_library(lib)
  lib = fs.normalize(lib)
  self:add_workspace_library(lib)

  -- add $path/lua
  if not endswith(lib, '/lua') and fs.dir_exists(lib .. '/lua') then
    self:add_runtime_dir(lib .. "/lua")
  end

  -- add $path/src
  if not endswith(lib, '/src') and fs.dir_exists(lib .. '/src') then
    self:add_runtime_dir(lib .. "/src")
  end

  -- add $path/lib
  if not endswith(lib, '/lib') and fs.dir_exists(lib .. '/lib') then
    self:add_runtime_dir(lib .. "/lib")
  end

  return self
end


---@param client? vim.lsp.Client
function Config:update_client_settings(client)
  client = client or lsp.get_clients({ name = NAME })[1]
  if not client then
    return
  end

  local settings = self.config.settings
  if deep_equal(client.settings, settings) then
    return
  end

  client.settings = deepcopy(settings)

  do
    -- avoid triggering `workspace/didChangeWorkspaceFolders` by tricking
    -- lspconfig into thinking that the client already knows about all of
    -- our workspace directories

    client.workspace_folders = client.workspace_folders or {}
    local seen = {}
    for _, item in ipairs(client.workspace_folders) do
      seen[item.name] = true
    end

    local resolver = self.resolver
    if resolver then
      for _, tree in ipairs(resolver.paths) do
        if tree.dir ~= "" and not seen[tree.dir] then
          seen[tree.dir] = true
          insert(client.workspace_folders, {
            name = tree.dir,
            uri = vim.uri_from_fname(tree.dir),
          })
        end
      end
    end
  end

  vim.notify("Updating LuaLS settings...")
  local ok = client:notify(workspaceDidChangeConfiguration,
                           { settings = settings })

  if not ok then
    vim.notify("Failed updating LuaLS settings", vim.log.levels.WARN)
  end
end


---@param dir string
---@return my.lua_ls.Config
function Config:add_ignore(dir)
  if self.ignore_dir:add(dir) then
    self.dirty = true
  end
  return self
end


---@param dir string
---@return my.lua_ls.Config
function Config:add_type_defs(dir)
  self.resolver:add_dir(dir, { source = SRC_TYPE_DEFS })
  self:add_workspace_library(dir)

  return self
end


---@param dir string
---@return my.lua_ls.Config
function Config:set_root_dir(dir)
  if dir ~= self.config.root_dir then
    self.dirty = true
  end

  self.config.root_dir = dir

  if dir then
    self.resolver:add_dir(dir, { source = SRC_WORKSPACE_ROOT })
  end

  return self
end


return Config
