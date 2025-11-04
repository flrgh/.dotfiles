local _M = {}

local find = string.find
local gsub = string.gsub

---@param haystack string
---@param needle string
---@return boolean
local function contains(haystack, needle)
  return find(haystack, needle, nil, true) ~= nil
end

_M.contains = contains

return _M
