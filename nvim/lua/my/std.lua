local _M = {}

_M.cmd = require("my.std.cmd")
_M.fs = require("my.std.fs")
_M.io = require("my.std.io")
_M.path = require("my.std.path")

_M.plugin = require("my.std.plugin")
_M.luamod = require("my.std.luamod")

_M.types = require("my.std.types")

_M.string = require("my.std.string")
_M.table = require("my.std.table")

_M.deep_copy = vim.deepcopy
_M.deep_equal = vim.deep_equal

_M.is_callable = _M.types.callable

_M.mutex = require("my.std.mutex")
_M.Mutex = _M.mutex.new

_M.set = require("my.std.set")
_M.Set = _M.set.new

return _M
