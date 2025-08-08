if require("my.constants").bootstrap then
  return
end

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
noremap[Ctrl.j] = Ctrl.w .. "j"
noremap[Ctrl.k] = Ctrl.w .. "k"
noremap[Ctrl.l] = Ctrl.w .. "l"
noremap[Ctrl.h] = Ctrl.w .. "h"

nnoremap(Ctrl.PageUp)
  :desc("Previous buffer")
  :cmd("bprev")

nnoremap(Ctrl.PageDown)
  :desc("Next buffer")
  :cmd("bnext")

nnoremap(Leader.w)
  :desc("Delete buffer")
  :cmd("bdelete")

nnoremap(Leader.Dot)
  :desc("Set working dirctory from file")
  :raw(":lcd %:p:h<CR>")

nnoremap(Leader.cf)
  :desc("Copy the current file path to the clipboard (unnamedplus register)")
  :raw(':let @+=expand("%:p")<CR>')

-- TODO: what do these do?
noremap.YY        = [["+y<CR>]]
noremap[Leader.p] = [[+gP<CR>]]

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
