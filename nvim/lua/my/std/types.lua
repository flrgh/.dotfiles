---@class my.std.types
local _M = {}

local type = type
local getmetatable = debug.getmetatable
local rawget = rawget

local EMPTY = {}

_M.deep_copy = vim.deepcopy
_M.deep_equal = vim.deep_equal

---@param v any
---@return boolean
function _M.callable(v)
  local typ = type(v)

  return typ == "function"
    or (typ == "table"
        and type(rawget(getmetatable(v) or EMPTY, "__call")) == "function")
end

return _M
