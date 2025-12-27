local clear = require("table.clear")
local new = require("table.new")
local pairs = pairs
local type = type
local next = next
local sort = table.sort

---@class my.std.table: tablelib
local _M = setmetatable({}, { __index = _G.table })

_M.new = new
_M.clear = clear
_M.extend = vim.tbl_extend

---@generic T
---@param src T
---@return T cloned
function _M.clone(src)
  if type(src) ~= "table" then
    error("input was not a table", 2)
  end

  local clone = new(#src, 0)
  for k, v in pairs(src) do
    clone[k] = v
  end

  return clone
end


---@generic K, V
---@param t table<K, V>
---@return K[]
function _M.keys(t)
  local keys = {}

  local n = 0
  local key
  while true do
    key = next(t, key)
    if key then
      n = n + 1
      keys[n] = key
    else
      break
    end
  end

  return keys
end
local table_keys = _M.keys


---@generic K, V
---@param t table<K, V>
---@param cmp? fun(a: K, b: K):boolean
---@return K[]
function _M.sorted_keys(t, cmp)
  local keys = table_keys(t)
  sort(keys, cmp)
  return keys
end


---@generic K, V
---@param t table<K, V>
---@return V[]
function _M.values(t)
  local values = {}

  local n = 0
  local key, value
  while true do
    key, value = next(t, key)
    if key then
      n = n + 1
      values[n] = value
    else
      break
    end
  end

  return values
end


return _M
