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

" Always use decimal for editing numbers
set nrformats=

" Don't enter visual mode when trying to select text
set mouse-=a
" Mouse wheel scrolling
map <ScrollWheelUp> <C-Y>
map <ScrollWheelDown> <C-E>

" Sane cursor placement
set scrolloff=10
nnoremap n nzz
nnoremap N Nzz
nnoremap * *zz
nnoremap # #zz

" Better navigation of panes/splits
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>

" Spacebar to toggle folds
nnoremap <Space> za

" New splits should open on the right and on the bottom
set splitbelow
set splitright

" Autoreload ~/.vimrc on save
autocmd! bufwritepost .vimrc nested source %

" Rebind <leader> key
let mapleader = ","

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

" Backspace can still delete indentation
set backspace=indent,eol,start
