set nocompatible

let mapleader=','

for f in split(glob('~/.config/nvim/conf.d/*'), '\n')
    exec 'source' f
endfor

