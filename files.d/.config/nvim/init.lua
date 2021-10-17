local function reload(mod)
  _G.package.loaded[mod] = nil
  return require(mod)
end

vim.g.mapleader = ','

reload 'config.plugins'

vim.cmd [[
  for f in split(glob('~/.config/nvim/conf.d/*'), '\n')
      exec 'source' f
  endfor
]]

-- these only have first party dependencies, so they can be hot-reloaded
reload 'config.settings'
reload 'config.mappings'

require 'eviline'
require 'config.lsp'
require 'config.treesitter'
