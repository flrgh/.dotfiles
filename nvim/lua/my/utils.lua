local _M = {}

_M.types = require("my.utils.types")
_M.string = require("my.utils.string")
_M.cmd = require("my.utils.cmd")
_M.fs = require("my.utils.fs")
_M.plugin = require("my.utils.plugin")
_M.luamod = require("my.utils.luamod")

_M.is_callable = _M.types.callable

return _M
