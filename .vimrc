" Vundle stuff
filetype off
" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
" 
" Plugins here
" 
"Bundle 'Lokaltog/powerline', {'rtp': 'powerline/bindings/vim/'}
Plugin 'gregsexton/MatchTag'
Plugin 'bling/vim-airline'
Plugin 'tpope/vim-fugitive'
Plugin 'tpope/vim-surround'
Plugin 'tpope/vim-markdown'
Plugin 'scrooloose/syntastic'
Plugin 'vim-perl/vim-perl'
Plugin 'flazz/vim-colorschemes'
Plugin 'guns/xterm-color-table.vim'
Plugin 'burnettk/vim-angular'
Plugin 'kien/ctrlp.vim'
Plugin 'rstacruz/sparkup'
call vundle#end()            " required
filetype plugin indent on    " required

" Airline font config
let g:airline_powerline_fonts = 1

" The colors!
:colorscheme Tomorrow-Night


" Syntax hilighting
:syntax on

" Numba lines
set number

" High-light current line
set cul

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

" Sane cursor placement
set scrolloff=10
nnoremap n nzz
nnoremap N Nzz
nnoremap * *zz
nnoremap # #zz

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

" Spacebar to toggle folds
nnoremap <Space> za

" Perl folding
let perl_fold = 1

" New splits should open on the right and on the bottom
set splitbelow
set splitright

" Autoreload ~/.vimrc on save
autocmd! bufwritepost .vimrc nested source %

" Rebind <leader> key
let mapleader = ","

" Silence Syntastic's style checking
let g:syntastic_quiet_messages = { "type": "style" }

" Function for running a command and then returning your cursor to its
" original position
function! Preserve(command)
    " Preparation: save last search, and cursor position.
    let _s=@/
    let l = line(".")
    let c = col(".")
    " Do the business:
    execute a:command
    " Clean up: restore previous search history, and cursor position
    let @/=_s
    call cursor(l, c)
endfunction

" Remove unwanted whitespace at the end of lines
nmap _$ :call Preserve("%s/\\s\\+$//e")<CR>
