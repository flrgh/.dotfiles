" Vundle stuff
filetype off
" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
" 
" Plugins here
" 
Bundle 'Lokaltog/powerline', {'rtp': 'powerline/bindings/vim/'}
Plugin 'tpope/vim-fugitive'
Plugin 'tpope/vim-surround'
Plugin 'scrooloose/syntastic'
call vundle#end()            " required
filetype plugin indent on    " required



" Syntax hilighting
:syntax on

" Numba lines
set nu

" The colors!
:colorscheme slate

" Highlight search results
:set hlsearch
:hi Search guibg=peru guifg=wheat cterm=none ctermfg=yellow ctermbg=black
nnoremap <CR> :noh<CR><CR>

" Tab is 4 spaces
set tabstop=4
set shiftwidth=4
set softtabstop=4
set expandtab

" Path management via pathogen
"execute pathogen#infect()
"call pathogen#helptags()

" Always use decimal for editing numbers
set nrformats=

" Mouse wheel scrolling
set mouse=a
map <ScrollWheelUp> <C-Y>
map <ScrollWheelDown> <C-E>

" Powwa line
let g:Powerline_symbols = 'fancy'
set nocompatible   " Disable vi-compatibility
set laststatus=2   " Always show the statusline
set encoding=utf-8 " Necessary to show Unicode glyphs

" Better navigation of panes/splits
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>

" New splits should open on the right and on the bottom
set splitbelow
set splitright

" Autoreload ~/.vimrc on save
autocmd! bufwritepost .vimrc source %

" Rebind <leader> key
let mapleader = ","

" Silence Syntastic's style checking
let g:syntastic_quiet_messages = { "type": "style" }
