local mod = require "my.utils.module"

local reload = mod.reload
-- these only have first party dependencies, so they can be hot-reloaded
reload 'my.config.globals'
reload 'my.augroup'
reload 'my.config.settings'
reload 'my.plugins'
reload 'my.config.mappings'
reload 'my.config.commands'
