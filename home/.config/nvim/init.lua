local mod = require "local.module"

mod.if_exists("impatient")

local reload = mod.reload
-- these only have first party dependencies, so they can be hot-reloaded
reload 'local.config.globals'
reload 'local.augroup'
reload 'local.config.settings'
reload 'local.config.plugins'
reload 'local.config.mappings'
reload 'local.config.commands'

require 'local.config.lsp'
