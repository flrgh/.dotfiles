if require("my.config.globals").bootstrap then
  return
end

local mod = require "my.utils.luamod"
local km = require "my.keymap"

local nnoremap = km.nnoremap
local map      = km.map
local noremap  = km.noremap
local vmap     = km.vmap
local vnoremap = km.vnoremap

local Ctrl = km.Ctrl
local Leader = km.Leader

-- split nav
nnoremap[Ctrl.J] = Ctrl.W .. Ctrl.J -- <C-W><C-J>
nnoremap[Ctrl.K] = Ctrl.W .. Ctrl.K -- <C-W><C-K>
nnoremap[Ctrl.L] = Ctrl.W .. Ctrl.L -- <C-W><C-L>
nnoremap[Ctrl.H] = Ctrl.W .. Ctrl.H -- <C-W><C-H>

-- window nav
noremap[Ctrl.j] = "<C-w>j"
noremap[Ctrl.k] = "<C-w>k"
noremap[Ctrl.l] = "<C-w>l"
noremap[Ctrl.h] = "<C-w>h"

-- buffer nav
-- NOTE: these might be overwritten by a plugin, such as `barbar.nvim`
nnoremap[Ctrl.PageUp]   = { ":bprev", "Previous buffer", silent = true }
nnoremap[Ctrl.PageDown] = { ":bnext", "Next buffer", silent = true }

nnoremap[Leader.Dot] = { ":lcd %:p:h", "Set working directory from current file" }

nnoremap[Leader.cf] = {
  ':let @+=expand("%:p")',
  "Copy the current file path to the clipboard (unnamedplus register)"
}

noremap.YY        = '"+y<CR>'
noremap[Leader.p] = '+gP<CR>'

-- maintain Visual Mode after shifting > and <
vmap["<"] = "<gv"
vmap[">"] = ">gv"

-- quickfix nav
map[Leader.qp]      = { ":cprevious", "QuickFix Previous" }
map[Leader.qn]      = { ":cnext",     "QuickFix Next" }
nnoremap[Leader.qq] = { ":cclose",    "QuickFix close" }

nnoremap[Leader.cd] = { ":cd %:p:h", "Change directory to that of the current file" }

nnoremap[Leader.ve] = { ":edit $MYVIMRC", "Edit vimrc/init.lua file" }

nnoremap[Leader.Space] = {":noh", "Clean search (highlight)", silent = true }

-- Search mappings: These will make it so that going to the next one in a
-- search will center on the line it's found in.
nnoremap.n = "nzzzv"
nnoremap.N = "Nzzzv"

-- Shift + J/K moves selected lines down/up in visual mode
-- https://old.reddit.com/r/neovim/comments/rfrgq5/is_it_possible_to_do_something_like_his_on/hog28q3/
vnoremap.J = { ":move '>+1<CR>gv=gv", 'Move selection up one line',   no_auto_cr = true }
vnoremap.K = { ":move '<-2<CR>gv=gv", 'Move selection down one line', no_auto_cr = true }

-- unbind q from macro things
nnoremap.q = { km.NOP, "(Macro Recording Disabled)" }

nnoremap["_$"] = {
  require("my.editor").strip_whitespace,
  "Strip trailing whitespace from all lines in the current buffer",
}
