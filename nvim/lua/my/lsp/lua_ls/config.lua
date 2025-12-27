local env = require("my.env")
local std = require("my.std")
local state = require("my.state")
local proto = require("vim.lsp.protocol")
local const = require("my.lsp.lua_ls.constants")
local DEFAULTS = require("my.lsp.lua_ls.defaults")
local health = require("user.health")

local pathlib = std.path
local luamod = std.luamod
local lsp = vim.lsp
local endswith = std.string.endswith
local insert = std.table.insert
local deep_copy = std.deep_copy
local deep_equal = std.deep_equal
local fmt = std.string.format
local path_exists = std.path.cache.exists
local path_type = std.path.cache.type
local path_is_file = std.path.cache.file_exists
local path_is_dir = std.path.cache.dir_exists
local path_is_abs = std.path.is_abs
local path_is_child = std.path.is_child

---@type string[]
local LUA_PATH_ENTRIES = luamod.LUA_PATH_ENTRIES

local SRC_TYPE_DEFS = const.SRC_TYPE_DEFS
local SRC_RUNTIME_PATH = const.SRC_RUNTIME_PATH
local SRC_WS_LIBRARY = const.SRC_WS_LIBRARY
local SRC_PLUGIN = const.SRC_PLUGIN
local SRC_WORKSPACE_ROOT = const.SRC_WORKSPACE_ROOT


local EMPTY = {}

local workspaceDidChangeConfiguration = proto.Methods.workspace_didChangeConfiguration

state.global.lua_lsp = state.global.lua_lsp or {}
local STATES = state.global.lua_lsp

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
---@field globals my.std.Set
---@field mutex my.std.Mutex
---@field _lls_meta_dir? string
local Config = {}
local Config_mt = { __index = Config }

---@param id integer|"default"
---@param defaults? my.lua_ls.Config
---@return my.lua_ls.Config
function Config.new(id, defaults)
  local self = setmetatable({
    id = id,
    client = nil,
    config = deep_copy(defaults or DEFAULTS),
    resolver = luamod.resolver.new(),
    meta = {},
    dirty = false,
    workspace_library = std.Set(),
    runtime_path = std.Set(),
    ignore_dir = std.Set(),
    addons = std.Set(),
    definitions = std.Set(),
    modules = std.Set(),
    globals = std.Set(),
    mutex = std.Mutex(),
  }, Config_mt)


  local Lua = self.config.settings.Lua
  self.globals:add_all(Lua.diagnostics.globals or EMPTY)
  Lua.diagnostics.globals = self.globals.items

  self.runtime_path:add_all(Lua.runtime.path or EMPTY)
  Lua.runtime.path = self.runtime_path.items

  self.workspace_library:add_all(Lua.workspace.library or EMPTY)
  Lua.workspace.library = self.workspace_library.items

  self.ignore_dir:add_all(Lua.workspace.ignoreDir or EMPTY)
  Lua.workspace.ignoreDir = self.ignore_dir.items

  self.addons:add_all(Lua.workspace.userThirdParty or EMPTY)
  Lua.workspace.userThirdParty = self.addons.items
  if self.addons.len > 0 then
    Lua.workspace.checkThirdParty = const.ApplyInMemory
  else
    Lua.workspace.checkThirdParty = const.Disable
  end

  local resolver = self.resolver

  for _, path in ipairs(self.runtime_path.items) do
    resolver:add_path(path, { source = "Lua.runtime.path" })
  end

  for path in resolver.package_path_entries() do
    self.runtime_path:add(path)
    resolver:add_path(path, { source = "package.path" })
  end
  for path in resolver.env_lua_path_entries() do
    self.runtime_path:add(path)
    resolver:add_path(path, { source = "$LUA_PATH" })
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
  local meta = tree and tree.meta or { source = SRC_RUNTIME_PATH }

  self.resolver:add_path(search, meta)

  if self.runtime_path:add(search) then
    self.dirty = true
    lsp.log.info({
      event = "insert Lua.runtime.path",
      path = search,
      meta = meta,
    })
  end

  return self
end


---@param dir string
---@param tree? my.lua.resolver.path
---@return my.lua_ls.Config
function Config:add_runtime_dir(dir, tree)
  if dir == "." or dir == "" or not path_is_dir(dir) then
    return self
  end

  return self:add_runtime_path(dir .. "/?.lua", tree)
             :add_runtime_path(dir .. "/?/init.lua", tree)
end


---@param dir string
---@param tree? my.lua.resolver.path
---@return my.lua_ls.Config
function Config:prepend_runtime_dir(dir, tree)
  assert(path_is_dir(dir))

  local runtime_paths = self.runtime_path:take()

  self:add_runtime_dir(dir, tree)

  for _, rt in ipairs(runtime_paths) do
    self:add_runtime_path(rt)
  end

  return self
end


---@param path string
---@param tree? my.lua.resolver.path
---@return my.lua_ls.Config
function Config:add_workspace_library(path, tree)
  if not path_exists(path) then
    return self
  end

  if path_type(path) == "file" then
    for _, lib in ipairs(self.workspace_library.items) do
      if path_is_child(lib, path) then
        return self
      end
    end
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
function Config:add_library(lib, meta)
  if not path_exists(lib) then
    return self
  end

  lib = pathlib.cache.normalize(lib)

  ---@type my.lua.resolver.path
  local tree = {
    dir = lib,
    suffixes = { "?.lua", "?/init.lua" },
    absolute = path_is_abs(lib),
    meta = meta or {},
  }

  self:add_workspace_library(lib, tree)

  -- add $path/lua
  if not endswith(lib, '/lua') and path_is_dir(lib .. "/lua") then
    self:add_runtime_dir(lib .. "/lua", tree)
  end

  -- add $path/src
  if not endswith(lib, '/src') and path_is_dir(lib .. "/src") then
    self:add_runtime_dir(lib .. "/src", tree)
  end

  -- add $path/lib
  if not endswith(lib, '/lib') and path_is_dir(lib .. "/lib") then
    self:add_runtime_dir(lib .. "/lib", tree)
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


---@param name string
---@return my.lua_ls.Config
function Config:add_global(name)
  if self.globals:add(name) then
    self.dirty = true
  end
  return self
end


---@param dir string
---@return my.lua_ls.Config
function Config:add_type_defs(dir)
  if path_is_dir(dir) then
    self:add_workspace_library(dir)
  end

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
  if self._lls_meta_dir then
    return self._lls_meta_dir
  end

  local rt = self.config.settings.Lua.runtime

  local meta = rt.meta or "${version} ${language} ${encoding}"

  local params = {
    version = rt.version or "LuaJIT",
    language = const.SERVER.LOCALE,
    encoding = rt.fileEncoding or "utf8",
  }

  local dirname = meta:gsub("%$%{([%w]+)%}", params)

  local meta_dir = const.SERVER.META_DIR .. "/" .. dirname

  vim.uv.fs_stat(meta_dir, function(err, stat)
    if err or not stat then
      health.error(const.NAME, "meta path (%q) does not exist", meta_dir)

    elseif stat.type == "directory" then
      health.ok(const.NAME, "meta dir (%q) found", meta_dir)

    else
      health.error(const.NAME, "meta path (%q) is not a directory", meta_dir)
    end
  end)

  self._lls_meta_dir = meta_dir
  return meta_dir
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
