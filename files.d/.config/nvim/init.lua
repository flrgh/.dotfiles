local mod = require "local.module"

mod.if_exists("impatient")

local reload = mod.reload
-- these only have first party dependencies, so they can be hot-reloaded
reload 'local.config.globals'
reload 'local.config.plugins'
reload 'local.config.settings'
reload 'local.config.mappings'

require 'local.config.lsp'
