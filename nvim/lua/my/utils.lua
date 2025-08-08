local _M = {}

local type = type
local getmetatable = debug.getmetatable

local EMPTY = {}


---@param v any
---@return boolean
function _M.is_callable(v)
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
