local find = string.find
local gsub = string.gsub
local byte = string.byte
local match = string.match
local type = type

---@class my.std.string: stringlib
local _M = setmetatable({}, { __index = _G.string })

local SPACE = byte(" ")
local TAB = byte("\t")
local NEWLINE = byte("\n")

---@param haystack string
---@param needle string
---@return boolean
local function contains(haystack, needle)
  return find(haystack, needle, nil, true) ~= nil
end

_M.contains = contains

---@param str string
---@return string
local function trim(str)
  local s = byte(str, 1)
  local e = byte(str, #str)

  if s == SPACE or s == TAB or s == NEWLINE
    or e == SPACE or e == TAB or e == NEWLINE
  then
    str = match(str, "^%s*(.-)%s*$") or str
  end

  return str
end

_M.trim = trim

---@param str string
---@param prefix string
---@return boolean
function _M.startswith(str, prefix)
  assert(type(str) == "string" and type(prefix) == "string")
  return (byte(str, 1)) == (byte(prefix, 1))
    and find(str, prefix, 1, true) == 1
end

_M.endswith = vim.endswith

return _M
