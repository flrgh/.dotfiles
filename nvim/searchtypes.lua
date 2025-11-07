require("my.lazy.bootstrap")("silent")

local luamod = require("my.std.luamod")
local plugin = require("my.std.plugin")
vim.print(vim.inspect(luamod.find_all_types(plugin.lua_dirs())))
