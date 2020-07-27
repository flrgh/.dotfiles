" CtrlP
Plug 'ctrlpvim/ctrlp.vim'

let g:ctrlp_user_command = ['.git', 'cd %s && git ls-files -co --exclude-standard']
