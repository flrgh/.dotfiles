---@class my.std.cache
local _M = {}

local table = require("my.std.table")
local tab_clear = table.clear
local insert = table.insert

local NIL = {}

---@type my.std.Cache[]
local CACHES = {}

---@type table<string, my.std.Cache>
local MAP = {}

---@param name string
---@return my.std.Cache
function _M.new(name)
  assert(type(name) == "string")

  if MAP[name] then
    return MAP[name]
  end

  local cache = {}
  local num_cached = 0

  ---@generic V
  ---@param key string
  ---@param cb? fun(key: string, ...: any):V, string|nil
  ---@param ...any
  ---@return V|nil
  ---@return boolean hit
  ---@return string? error
  local function get(key, cb, ...)
    local value = cache[key]
    if value ~= nil then
      if value == NIL then
        value = nil
      end
      return value, true
    end

    if cb then
      local err
      value, err = cb(key, ...)
      if err then
        return nil, false, err
      end

      num_cached = num_cached + 1

      if value == nil then
        cache[key] = NIL
      else
        cache[key] = value
      end
    end

    return value, false
  end

  ---@param key string
  ---@param value any
  local function set(key, value)
    if value == nil then
      value = NIL
    end

    if cache[key] == nil then
      num_cached = num_cached + 1
    end

    cache[key] = value
  end

  ---@param key string
  ---@return boolean
  local function has(key)
    return cache[key] ~= nil
  end

  ---@param key string
  local function del(key)
    if cache[key] ~= nil then
      num_cached = num_cached - 1
    end
    cache[key] = nil
  end

  local function clear()
    num_cached = 0
    tab_clear(cache)
  end

  local function size()
    return num_cached
  end

  ---@class my.std.Cache
  local self = {
    get = get,
    has = has,
    del = del,
    clear = clear,
    set = set,
    size = size,
    name = function()
      return name
    end,
  }

  table.insert(CACHES, self)
  MAP[name] = self

  return self
end

return _M
