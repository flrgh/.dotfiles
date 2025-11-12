---@class my.std
---
---@field cmd    my.std.cmd
---@field fs     my.std.fs
---@field io     my.std.io
---@field luamod my.std.luamod
---@field path   my.std.path
---@field string my.std.string
---@field table  my.std.table
---@field types  my.std.types
local _M = {}

setmetatable(_M, {
  __index = function(_, key)
    local mod = require("my.std." .. key)
    _M[key] = mod
    return mod
  end,
})

local types = require("my.std.types")
_M.types = types
_M.deep_copy = types.deep_copy
_M.deep_equal = types.deep_equal

_M.mutex = require("my.std.mutex")
_M.Mutex = _M.mutex.new

_M.set = require("my.std.set")
_M.Set = _M.set.new

return _M
