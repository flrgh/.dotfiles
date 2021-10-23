local function reload(mod)
  _G.package.loaded[mod] = nil
  return require(mod)
end

vim.g.mapleader = ','

reload 'local.config.plugins'

-- these only have first party dependencies, so they can be hot-reloaded
reload 'local.config.settings'
reload 'local.config.mappings'

require 'eviline'
require 'local.config.lsp'
