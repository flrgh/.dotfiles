local km = require 'local.keymap'

local nnoremap = km.nnoremap
local map      = km.map
local noremap  = km.noremap
local vmap     = km.vmap

-- split nav
nnoremap.ctrl.J = '<C-W><C-J>'
nnoremap.ctrl.K = '<C-W><C-K>'
nnoremap.ctrl.L = '<C-W><C-L>'
nnoremap.ctrl.H = '<C-W><C-H>'

-- window nav
noremap.ctrl.j = '<C-w>j'
noremap.ctrl.k = '<C-w>k'
noremap.ctrl.l = '<C-w>l'
noremap.ctrl.h = '<C-w>h'

-- buffer nav
nnoremap.ctrl.PageUp   = {':bprev', silent = true }
nnoremap.ctrl.PageDown = {':bnext', silent = true }

-- close buffer
nnoremap.leader.w = ':Bwipeout'

-- open current line in github browser
nnoremap.leader.o = ':.GBrowse'

-- set working directory from current file
nnoremap.leader['.'] = ':lcd %:p:h'

-- copy the current file path to the clipboard (unnamedplus register)
nnoremap.leader.cf = ':let @+=expand("%:p")'

noremap.YY       = '"+y<CR>'
noremap.leader.p = '+gP<CR>'

-- maintain Visual Mode after shifting > and <
vmap['<'] = '<gv'
vmap['>'] = '>gv'

-- quickfix nav
map.leader.qp      = ':cprevious'
map.leader.qn      = ':cnext'
nnoremap.leader.qq = ':cclose'

-- Change directory to that of the current file
nnoremap.leader.cd = ':cd %:p:h'

-- edit vimrc
nnoremap.leader.ve = ':edit $MYVIMRC'

-- Clean search (highlight)
nnoremap.leader['<space>'] = {':noh', silent = true }

-- Search mappings: These will make it so that going to the next one in a
-- search will center on the line it's found in.
nnoremap.n = 'nzzzv'
nnoremap.N = 'Nzzzv'
