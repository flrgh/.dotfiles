if require("my.config.globals").bootstrap then
  return
end

local g = vim.g
local o = vim.o
local opt = vim.opt
local cmd = vim.cmd

g.mapleader = ','

o.encoding      = 'utf-8'
o.bomb = false
o.fileformat    = 'unix'
o.fileformats   = 'unix'

o.autoread = true

-- fix backspace indent
opt.backspace = {'indent', 'eol', 'start'}

-- allow hidden buffers
o.hidden = true

-- search settings
o.hlsearch   = true
o.incsearch  = true
o.ignorecase = true
o.smartcase  = true

o.splitbelow = true
o.splitright = true

opt.diffopt:append("vertical")

opt.wildignore:append {
  '*.db',
  '*.min.css',
  '*.min.js',
  '*.o',
  '*.obj',
  '*.pyc',
  '*.so',
  '*.sqlite',
  '*.swp',
  '*.zip',
  '*/tmp/*',
}

o.shell = '/bin/bash'

-- session management
o.backup   = false
o.swapfile = false

-- mouse
o.mousemodel = 'popup_setpos'
o.mouse      = 'nv'

-- clipboard register
-- TODO: unset this for OSC 52 support (doesn't work right now)
o.clipboard  = 'unnamedplus'

-- visual settings
opt.listchars     = { eol = '$' }
o.ruler         = true
o.number        = true
o.background    = 'dark'
o.termguicolors = true
o.gfn           = 'Monospace 10'
o.signcolumn    = 'yes'

-- no cursor blinking
opt.gcr = 'a:blinkon0'

o.scrolloff   = 3
o.laststatus  = 2
o.title       = true
o.titlestring = '%F'

o.modeline   = true
o.modelines  = 10

-- no folding
o.foldenable = false

o.tagfunc = 'v:lua.vim.lsp.tagfunc'

-- explicitly disabling these keeps :checkhealth output clean
g.loaded_node_provider = 0
g.loaded_perl_provider = 0
g.loaded_python3_provider = 0
g.loaded_ruby_provider = 0

-- correct my various mispellings of `local`
cmd.iabbrev("loacl", "local")
cmd.iabbrev("laocl", "local")
cmd.iabbrev("lcoal", "local")
cmd.iabbrev("locla", "local")
