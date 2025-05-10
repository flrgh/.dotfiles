local require = require

require "my.constants"
require "my.workspace"
require "my.augroup"
require "my.config.settings"
require "my.plugins"
require "my.config.mappings"
require "my.config.commands"

require("my.config.lsp").init()
