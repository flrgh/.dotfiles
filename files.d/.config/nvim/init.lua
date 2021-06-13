vim.g.mapleader = ','

require 'config.plugins'

vim.cmd [[
  for f in split(glob('~/.config/nvim/conf.d/*'), '\n')
      exec 'source' f
  endfor
]]

require 'config.settings'
require 'eviline'
require 'config.lsp'
require 'config.treesitter'
