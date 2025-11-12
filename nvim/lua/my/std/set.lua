local table = require("my.std.table")
local clear = table.clear
local clone = table.clone

---@class my.std.Set
---@field items string[]
---@field map { [string]: boolean }
---@field len integer
local Set = {}
local Set_mt = { __index = Set }

---@return my.std.Set
function Set.new()
  local self = setmetatable({
    items = {},
    map = {},
    len = 0,
  }, Set_mt)
  return self
end


---@param elem string
---@return boolean added
function Set:add(elem)
  local map = self.map
  if not map[elem] then
    map[elem] = true
    local len = self.len + 1
    self.items[len] = elem
    self.len = len
    return true
  end
  return false
end


---@return my.std.Set
function Set:clear()
  clear(self.items)
  clear(self.map)
  self.len = 0
  return self
end


---@return string[]
function Set:take()
  local items = clone(self.items)
  self:clear()
  return items
end


---@param items string[]
---@return my.std.Set
function Set.from(items)
  local self = Set.new()
  self:add_all(items)
  return self
end


---@param items string[]
---@return boolean added
function Set:add_all(items)
  local added = false
  for i = 1, #items do
    if self:add(items[i]) then
      added = true
    end
  end
  return added
end


---@param item string
---@return boolean
function Set:contains(item)
  return self.map[item] ~= nil
end

---@class my.std.set
local _M = {}
_M.new = Set.new
_M.from = Set.from

return _M
