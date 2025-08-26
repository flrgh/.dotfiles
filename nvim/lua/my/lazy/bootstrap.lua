vim.print("Bootstrapping plugins\n")

vim.go.loadplugins = true

local conf = require("my.lazy.config")
local plugins = require("my.plugins")
local lazy = require("lazy")


-- block until the entire restore task completes
conf.wait = true

conf.spec = plugins
lazy.setup(conf)
lazy.restore(conf)
lazy.build(conf)

vim.print("Plugin bootstrap complete\n")
