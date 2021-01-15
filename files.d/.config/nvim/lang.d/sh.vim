augroup sh
  au!

  " make $ a keyword
  au Filetype sh setlocal iskeyword+=$

  " force utf-8
  au Filetype sh setlocal fileencoding=utf-8

  " indentation is 4 spaces
  au Filetype sh setlocal expandtab
  au Filetype sh setlocal tabstop=4
  au Filetype sh setlocal shiftwidth=4
  au Filetype sh setlocal softtabstop=4

  " ale shellcheck exclusions
  "
  " SC2059 - using printf with a variable in the template
  " https://github.com/koalaman/shellcheck/wiki/SC2059
  "
  " SC1091 - don't complain when shellcheck can't find a sourced file
  " https://github.com/koalaman/shellcheck/wiki/SC1091
  "
  " SC2181 - checking the last command's return code with `$?`
  " https://github.com/koalaman/shellcheck/wiki/SC2181
  "
  au Filetype sh let g:ale_sh_shellcheck_exclusions = "SC2059,SC1091,SC2181"

  " shfmt
  "
  "  -i uint   indent: 0 for tabs (default), >0 for number of spaces
  "  -bn       binary ops like && and | may start a line
  "  -ci       switch cases will be indented
  "  -sr       redirect operators will be followed by a space
  "  -kp       keep column alignment paddings
  "
  au Filetype sh let g:ale_sh_shfmt_options = '-i 4 -ci -bn -sr -kp'

augroup END
