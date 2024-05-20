require("barbar").setup({
  icons = {
    separator = {
      left = '▎',
    },
    inactive = {
      separator = {
        left =  '▎',
      },
    },
    pinned = {
      button = '車',
    },
    button = '',
    modified = {
      button= '●',
    },

  },
  animation = false,
  auto_hide = false,
  closable = true,
  clickable = true,
  maximum_padding = 4,
  maximum_length = 30,
  semantic_letters = true,
  no_name_title = nil,
})
