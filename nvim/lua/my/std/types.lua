---@class my.std.types
local _M = {}

local type = type
local getmetatable = debug.getmetatable

local EMPTY = {}

_M.deep_copy = vim.deepcopy

_M.deep_equal = vim.deep_equal

---@param v any
---@return boolean
function _M.callable(v)
  if v == nil then
    return false
  end

  local typ = type(v)

  if typ == "function" then
    return true
  end

  local mt = getmetatable(v)
  if not mt then
    return false
  end

  return type(mt.__call) == "function"
end


return _M
