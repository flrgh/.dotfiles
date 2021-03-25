" boilerplate

let vimplug_exists=expand('~/.config/nvim/autoload/plug.vim')

let g:vim_bootstrap_editor = "nvim"				" nvim or vim

if !filereadable(vimplug_exists)
  if !executable("curl")
    echoerr "You have to install curl or first install vim-plug yourself!"
    execute "q!"
  endif
  echo "Installing Vim-Plug..."
  echo ""
  silent !\curl -fLo ~/.config/nvim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  let g:not_finish_vimplug = "yes"

  autocmd VimEnter * PlugInstall
endif

" Required:
call plug#begin(expand('~/.config/nvim/plugged'))


" Basic plugins with no config

" put git diff indicators in the gutter
Plug 'airblade/vim-gitgutter'

" hilight trailing whitespace
Plug 'bronson/vim-trailing-whitespace'

" load tags in side pane
Plug 'majutsushi/tagbar'

" highlight indentation levels
Plug 'Yggdroot/indentLine'
Plug 'lukas-reineke/indent-blankline.nvim'

" useful for targetting surrounding quotes/parens/etc
Plug 'tpope/vim-surround'

" syntax hilight for .jq files
Plug 'vito-c/jq.vim', {'for': 'jq'}

" syntax for .tf files
Plug 'hashivim/vim-terraform', { 'for': 'tf' }

" running shfmt commands on the buffer
Plug 'z0mbix/vim-shfmt', { 'for': 'sh' }

" syntax for .bats files
Plug 'aliou/bats.vim', { 'for': 'bats' }

"" Vim-Session
Plug 'xolox/vim-misc'
Plug 'xolox/vim-session'

" fantastic git integration
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-rhubarb'

"" Color
Plug 'tomasr/molokai'
Plug 'morhetz/gruvbox'
Plug 'challenger-deep-theme/vim', { 'as': 'challenger-deep' }
Plug 'mhinz/vim-janah'
Plug 'mhartington/oceanic-next'
Plug 'joshdick/onedark.vim'
Plug 'tjdevries/colorbuddy.vim'
Plug 'tjdevries/gruvbuddy.nvim'
Plug 'sainnhe/sonokai'

" Buffer management
Plug 'moll/vim-bbye'

" PHP lang
Plug 'StanAngeloff/php.vim'

" align!
Plug 'junegunn/vim-easy-align'
" Start interactive EasyAlign in visual mode (e.g. vipga)
xmap ga <Plug>(EasyAlign)
" Start interactive EasyAlign for a motion/text object (e.g. gaip)
nmap ga <Plug>(EasyAlign)

" support .editorconfig files
Plug 'editorconfig/editorconfig-vim'

" auto hlsearch stuff
Plug 'romainl/vim-cool'
for f in split(glob('~/.config/nvim/plugins.d/*.vim'), '\n')
    exe 'source' f
endfor


call plug#end()

filetype plugin indent on
