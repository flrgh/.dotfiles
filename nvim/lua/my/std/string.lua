---@class my.std.string: stringlib
local _M = setmetatable({}, { __index = _G.string })


local glob_to_lpeg = require("vim.glob").to_lpeg
local glob_match = glob_to_lpeg("*").match


local find = string.find
local gsub = string.gsub
local byte = string.byte
local match = string.match
local type = type


local SPACE = byte(" ")
local TAB = byte("\t")
local NEWLINE = byte("\n")

---@type table<string, vim.lpeg.Pattern>
local GLOBS = {}


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


---@param pattern string
---@param subject string
---@return boolean
function _M.globmatch(pattern, subject)
  -- XXX: not sure if correct behavior, but it works for how I'm using this
  if pattern == subject then
    return true
  end

  local glob = GLOBS[pattern]
  if not glob then
    glob = assert(glob_to_lpeg(pattern))
    GLOBS[pattern] = glob
  end

  return glob_match(glob, subject) and true or false
end

return _M
