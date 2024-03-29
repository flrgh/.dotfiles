if require("local.config.globals").bootstrap then
  return
end

local g = vim.g
local opt = vim.opt

g.mapleader = ','

opt.encoding      = 'utf-8'
opt.fileencoding  = 'utf-8'
opt.fileencodings = 'utf-8'
opt.bomb          = true
opt.binary        = true
opt.fileformat    = 'unix'
opt.fileformats   = 'unix'

-- fix backspace indent
opt.backspace = {'indent', 'eol', 'start'}

-- allow hidden buffers
opt.hidden = true

-- search settings
opt.hlsearch   = true
opt.incsearch  = true
opt.ignorecase = true
opt.smartcase  = true

opt.splitbelow = true
opt.splitright = true

opt.diffopt = opt.diffopt + 'vertical'

opt.wildignore:append {
  '*/tmp/*',
  '*.so',
  '*.swp',
  '*.zip',
  '*.pyc',
  '*.db',
  '*.sqlite',
  '*.min.js',
  '*.min.css',
}

opt.shell = '/bin/bash'

-- session management
opt.backup   = false
opt.swapfile = false

-- mouse
opt.mousemodel = 'popup'
opt.mouse      = 'nv'

-- clipboard register
opt.clipboard  = 'unnamedplus'

-- visual settings
vim.cmd [[syntax on]]
opt.listchars     = { eol = '$' }
opt.ruler         = true
opt.number        = true
opt.background    = 'dark'
opt.termguicolors = true
opt.gfn           = 'Monospace 10'
opt.signcolumn    = 'yes'

-- no cursor blinking
opt.gcr = 'a:blinkon0'

opt.scrolloff   = 3
opt.laststatus  = 2
opt.title       = true
opt.titlestring = '%F'

opt.modeline   = true
opt.modelines  = 10

-- no folding
opt.foldenable = false

opt.tagfunc = 'v:lua.vim.lsp.tagfunc'
