local clear = require("table.clear")
local new = require("table.new")
local pairs = pairs
local type = type

---@class my.std.table: tablelib
local _M = setmetatable({}, { __index = _G.table })

_M.new = new
_M.clear = clear

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


return _M
