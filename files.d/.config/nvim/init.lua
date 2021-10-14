vim.g.mapleader = ','

require 'config.plugins'

vim.cmd [[
  for f in split(glob('~/.config/nvim/conf.d/*'), '\n')
      exec 'source' f
  endfor
]]

local function reload(mod)
  package.loaded[mod] = nil
  return require(mod)
end

-- these only have first party dependencies, so they can be hot-reloaded
reload 'config.settings'
reload 'config.mappings'

require 'eviline'
require 'config.lsp'
require 'config.treesitter'
require 'config.formatters'
