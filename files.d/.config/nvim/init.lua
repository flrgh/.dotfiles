local reload = require('local.module').reload

-- these only have first party dependencies, so they can be hot-reloaded
reload 'local.config.plugins'
reload 'local.config.settings'
reload 'local.config.mappings'

require 'local.config.lsp'
