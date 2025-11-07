local user_const = require("my.constants")
local std = require("my.std")
local storage = require("my.storage")
local proto = require("vim.lsp.protocol")
local const = require("my.lsp.lua_ls.constants")
local DEFAULTS = require("my.lsp.lua_ls.defaults")

local fs = std.fs
local luamod = std.luamod
local lsp = vim.lsp
local endswith = std.string.startswith
local insert = std.table.insert
local deep_copy = std.deep_copy
local deep_equal = std.deep_equal
local fmt = std.string.format

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

local DEBUG = vim.log.levels.DEBUG

---@param paths my.std.Set
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
---@field workspace_library my.std.Set
---@field runtime_path my.std.Set
---@field ignore_dir my.std.Set
---@field addons my.std.Set
---@field definitions my.std.Set
---@field modules my.std.Set
---@field mutex my.std.Mutex
local Config = {}
local Config_mt = { __index = Config }

---@param id integer|"default"
---@param config? my.lsp.config.Lua
---@return my.lua_ls.Config
function Config.new(id, config)
  local self = setmetatable({
    id = id,
    client = nil,
    config = deep_copy(config),
    resolver = luamod.resolver.new(),
    meta = {},
    dirty = false,
    workspace_library = std.Set(),
    runtime_path = std.set.from({ "?.lua", "?/init.lua" }),
    ignore_dir = std.Set(),
    addons = std.Set(),
    definitions = std.Set(),
    modules = std.Set(),
    mutex = std.Mutex(),
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
      if parent == "."
        or parent == self.config.root_dir
        or self.workspace_library:contains(parent)
      then
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

  client.settings = deep_copy(settings)

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


---@return string
function Config:lls_meta_dir()
  local rt = self.config.settings.Lua.runtime

  local version = rt.version or "LuaJIT"
  local locale = "en-us"
  local encoding = rt.fileEncoding or "utf8"

  return fmt("%s/lua-lsp/%s %s %s",
             user_const.nvim.state,
             version,
             locale,
             encoding)
end

---@param reason string
function Config:lock(reason)
  if type(reason) ~= "string" then
    error("lock reason (string) is required", 2)
  end

  self:debug("locking (%s)", reason)
  self.mutex:acquire()

  self:debug("locked (%s)", reason)
  self.lock_reason = reason
end

function Config:unlock()
  assert(type(self.lock_reason) == "string")

  self:debug("unlocking (%s)", self.lock_reason)
  self.lock_reason = nil

  self.mutex:release()
end

---@param action string
---@param fn fun(config: my.lua_ls.Config)
function Config:with_mutex(action, fn)
  self:lock(action)
  pcall(fn, self)
  self:unlock()
end
Config.with_mutex = vim.schedule_wrap(Config.with_mutex)


---@param f string
---@param ...any
function Config:debug(f, ...)
  local msg = "[lua_ls(" .. self.id .. ")] " .. fmt(f, ...)
  vim.notify(msg, DEBUG)
end

return Config
