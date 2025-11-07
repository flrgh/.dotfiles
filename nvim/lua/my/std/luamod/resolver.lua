local fs = require "my.std.fs"
local sw = require "my.std.stopwatch"
local const = require "my.constants"
local clear = require("table.clear")

local insert = table.insert
local find = string.find
local sub = string.sub
local gsub = string.gsub
local gmatch = string.gmatch

---@type { [string]: boolean }
local FS_CACHE = {}

---@param path string
---@param absolute? boolean
local function file_exists(path, absolute)
  if not absolute then
    return fs.file_exists(path)
  end

  local exists = FS_CACHE[path]
  if exists == nil then
    exists = fs.file_exists(path) or false
    FS_CACHE[path] = exists
  end

  return exists
end


local function noop() end

---@return fun():string|nil
local function package_path_entries()
  return gmatch(package.path, "[^;]+")
end

---@return fun():string|nil
local function env_lua_path_entries()
  local lua_path = os.getenv("LUA_PATH")
  return gmatch(lua_path or "", "^[^;]+")
end

local SRC_PACKAGE_PATH = "package.path"
local SRC_LUA_PATH = "$LUA_PATH"


---@class my.lua.resolver.module
---
---@field tree my.lua.resolver.path
---@field fname string


---@alias my.lua.resolver.path.meta table<string, any>


---@class my.lua.resolver.path
---
---@field dir      string
---@field suffixes string[]
---@field absolute boolean
---@field meta     my.lua.resolver.path.meta


---@class my.lua.resolver
---
---@field paths my.lua.resolver.path[]
---
---@field module_cache table<string, my.lua.resolver.module>
---
---@field dir_lookup table<string, my.lua.resolver.path>
local resolver = {}
local resolver_mt = { __index = resolver }

resolver.package_path_entries = package_path_entries
resolver.env_lua_path_entries = env_lua_path_entries
resolver.SRC_PACKAGE_PATH = SRC_PACKAGE_PATH
resolver.SRC_LUA_PATH = SRC_LUA_PATH


---@return fun():my.lua.resolver.path|nil
function resolver:iter_paths()
  local i = 0
  local paths = self.paths
  return function()
    i = i + 1
    return paths[i]
  end
end


---@return fun():string|nil, my.lua.resolver.path
function resolver:iter_search_paths()
  local path_i = 0
  local suffix_i = 0
  local paths = self.paths
  local num_paths = #paths
  local num_suffixes = 0

  ---@type my.lua.resolver.path
  local path

  return function()
    if suffix_i > num_suffixes then
      path = nil
      suffix_i = 0
    end

    if not path then
      path_i = path_i + 1
      path = paths[path_i]
    end

    if not path then
      return
    end

    suffix_i = suffix_i + 1
    return path.dir .. path.suffixes[suffix_i]
  end
end


---@param name string
---@param debug boolean?
---@return my.lua.resolver.module? mod
---@return string[]? tried
function resolver:find_module(name, debug)
  if debug == nil then
    debug = self.debug
  end

  local mod_cache = self.module_cache
  if not debug then
    local result = mod_cache[name]
    if result then
      return result
    end
  end

  local done = noop
  if debug then
    done = sw.new("luamod.resolve(" .. name .. ")", 50)
  end

  local slashed = gsub(name, "%.", "/")

  local paths = self.paths
  local tried = debug and {} or nil

  for i = 1, #paths do
    local path = paths[i]
    local dir = path.dir
    local absolute = path.absolute
    local prefix = (dir == "" and "")
                or (dir .. "/")

    local suffixes = path.suffixes
    for j = 1, #suffixes do
      local suf = suffixes[j]
      local fname = slashed .. suf
      local fullpath = prefix .. fname

      if tried then
        insert(tried, fullpath)
      end

      if file_exists(fullpath, absolute) then
        local entry = {
          fname = fname,
          tree  = path,
        }

        mod_cache[name] = entry

        done()
        return entry
      end
    end
  end

  done()
  return nil, tried
end

---@param path string
---@param meta? my.lua.resolver.path.meta
---@return my.lua.resolver
function resolver:add_path(path, meta)
  local dir, suffix

  local pos = assert(find(path, "?", nil, true))

  if pos then
    dir = sub(path, 1, pos - 1)
    suffix = sub(path, pos + 1) -- .lua or /init.lua
  end

  return self:add_search(dir, suffix, meta)
end


---@param dir string
---@param meta? my.lua.resolver.path.meta
---@return my.lua.resolver
function resolver:add_dir(dir, meta)
  return self:add_search(dir, ".lua", meta)
             :add_search(dir, "/init.lua", meta)
end

---@param dir string
---@param suffix string
---@param meta? my.lua.resolver.path.meta
---@return my.lua.resolver
function resolver:add_search(dir, suffix, meta)
  assert(type(dir) == "string")
  assert(type(suffix) == "string")

  -- little bit of normalization
  if dir == "" then
    dir = "."
  end
  if #dir > 1 then
    dir = gsub(dir, "/+$", "")
  end

  local path = self.dir_lookup[dir]

  if path then
      local suffixes = path.suffixes

      for j = 1, #suffixes do
        if suffix == suffixes[j] then
          -- nothing to do
          return self
        end
      end

      insert(suffixes, suffix)
  else
    path = {
      dir = dir,
      suffixes = { suffix },
      absolute = dir:sub(1, 1) == "/",
      meta = meta or {},
    }

    self.dir_lookup[dir] = path
    insert(self.paths, path)
  end

  return self
end

---@return my.lua.resolver
function resolver:add_env_lua_path()
  for path in env_lua_path_entries() do
    self:add_path(path, { source = SRC_LUA_PATH })
  end

  return self
end

---@return my.lua.resolver
function resolver:add_lua_package_path()
  for path in package_path_entries() do
    self:add_path(path, { source = SRC_PACKAGE_PATH })
  end

  return self
end

function resolver:purge_cache()
  clear(self.module_cache)
  self:purge_fs_cache()
end

function resolver:purge_fs_cache()
  clear(FS_CACHE)
end


---@return my.lua.resolver
function resolver.new()
  local self = setmetatable({
    paths = {},
    module_cache = {},
    debug = const.debug or false,
    dir_lookup = {},
  }, resolver_mt)

  return self
end


---@return my.lua.resolver
function resolver.default()
  return resolver.new():add_lua_package_path()
end


return resolver
