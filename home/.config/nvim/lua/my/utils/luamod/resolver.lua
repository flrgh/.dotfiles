local _M = {}

local fs = require "my.utils.fs"

local insert = table.insert
local find = string.find
local sub = string.sub
local gsub = string.gsub
local pairs = pairs
local file_exists = fs.file_exists

--- shallow table merge
local function merge(a, b)
  if b then
    a = a or {}

    for k, v in pairs(b) do
      a[k] = v
    end
  end

  return a
end

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
local resolver = {}


---@param name string
---@param debug boolean?
---@return my.lua.resolver.module? mod
---@return string[]? tried
function resolver:find_module(name, debug)
  local mod_cache = self.module_cache
  local result = mod_cache[name]
  if result then
    return result
  end

  local slashed = gsub(name, "%.", "/")

  local fs_cache = self.fs_cache
  local paths = self.paths
  local tried
  if debug then tried = {} end

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

        return entry
      end
    end
  end

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
  if self:has_dir(dir) then
    return self
  end

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
  dir = gsub(dir, "/+$", "")

  local paths = self.paths
  for i = 1, #paths do
    local path = paths[i]

    if path.dir == dir then
      path.meta = merge(path.meta, meta)

      local suffixes = path.suffixes

      for j = 1, #suffixes do
        if suffix == suffixes[j] then
          -- nothing to do
          return self
        end
      end

      -- found existing dir, insert suffix
      insert(suffixes, suffix)
      return self
    end
  end

  insert(paths, {
    dir = dir,
    suffixes = { suffix },
    absolute = dir:sub(1, 1) == "/",
    meta = meta or {},
  })

  return self
end

---@param dir string
---@return boolean
function resolver:has_dir(dir)
  for _, p in ipairs(self.paths) do
    if p.dir == dir then
      return true
    end
  end

  return false
end

function resolver:purge_cache()
  self.module_cache = {}
  self.fs_cache = {}
end

local resolver_mt = { __index = resolver }

---@return my.lua.resolver
function _M.new()
  local self = setmetatable({
    paths = {},
    module_cache = {},
    fs_cache = {},
  }, resolver_mt)

  return self
end

return _M
