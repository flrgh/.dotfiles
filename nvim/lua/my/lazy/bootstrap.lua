vim.go.loadplugins = true

local conf = require("my.lazy.config")
local plugins = require("my.plugins")
local lazy = require("lazy")

conf.spec = plugins
lazy.setup(conf)
lazy.restore(conf)
lazy.build(conf)
