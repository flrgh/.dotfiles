local _M = {}

local fs = require "my.utils.fs"
local sw = require "my.utils.stopwatch"
local const = require "my.constants"

local insert = table.insert
local find = string.find
local sub = string.sub
local gsub = string.gsub
local file_exists = fs.file_exists

local function noop() end

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
---@field fs_cache table<string, boolean>
---
---@field dir_lookup table<string, my.lua.resolver.path>
local resolver = {}


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

  local fs_cache = self.fs_cache
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

      local exists = fs_cache[fullpath]
      if exists == nil then
        exists = file_exists(fullpath) or false
        if absolute then
          fs_cache[fullpath] = exists
        end
      end

      if tried then
        insert(tried, fullpath)
      end

      if exists then
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

function resolver:add_env_lua_path()
  local lua_path = os.getenv("LUA_PATH") or ""

  lua_path:gsub("[^;]+", function(path)
    if path ~= "" then
      self:add_path(path, { source = "$LUA_PATH" })
    end
  end)

  return self
end

function resolver:add_lua_package_path()
  package.path:gsub("[^;]+", function(path)
    if path ~= "" then
      self:add_path(path, { source = "package.path" })
    end
  end)

  return self
end

function resolver:purge_cache()
  self.module_cache = {}
  self:purge_fs_cache()
end

function resolver:purge_fs_cache()
  self.fs_cache = {}
end

local resolver_mt = { __index = resolver }


---@return my.lua.resolver
function _M.new()
  local self = setmetatable({
    paths = {},
    module_cache = {},
    fs_cache = {},
    debug = const.debug or false,
    dir_lookup = {},
  }, resolver_mt)

  return self
end


function _M.default()
  return _M.new():add_lua_package_path()
end


return _M
