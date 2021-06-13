for f in split(glob('~/.config/nvim/lang.d/*.vim'), '\n')
    exe 'source' f
endfor
