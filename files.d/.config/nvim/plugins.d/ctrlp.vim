" CtrlP
Plug 'ctrlpvim/ctrlp.vim'

if executable('rg')
    let g:ctrlp_user_command = 'rg %s --files --hidden --color=never --glob "!.git/**" --glob ""'
else
    let g:ctrlp_user_command = ['.git', 'cd %s && git ls-files -co --exclude-standard']
endif
