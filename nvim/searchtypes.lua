require("my.env")

local plugins = require("my.plugins")
plugins.load()

local luamod = require("my.std.luamod")
vim.print(vim.inspect(luamod.find_all_types(plugins.lua_dirs())))
