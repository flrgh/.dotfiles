au BufNewFile,BufRead *.lua setlocal expandtab tabstop=2 shiftwidth=2 softtabstop=2
augroup lua
  au!
  au FileType lua setlocal expandtab
  au FileType lua setlocal tabstop=2
  au FileType lua setlocal shiftwidth=2
  au FileType lua setlocal softtabstop=2

augroup END
