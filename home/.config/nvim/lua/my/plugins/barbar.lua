﻿require("barbar").setup({
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
      button = '📌',
    },
    button = 'x',
    modified = {
      button= '●',
    },
    filetype = {
      enabled = true,
    },
    preset = "default",
    separator_at_end = true,
  },
  animation = false,
  auto_hide = false,
  closable = true,
  clickable = true,
  maximum_padding = 4,
  maximum_length = 30,
  semantic_letters = true,
  no_name_title = nil,
  insert_at_end = true,
  insert_at_start = false,
})

local km = require "my.keymap"
local nnoremap = km.nnoremap

nnoremap[km.Ctrl.PageUp]   = { ":BufferPrevious", "Previous buffer" }
nnoremap[km.Ctrl.PageDown] = { ":BufferNext", "Next buffer" }
nnoremap[km.Leader.w]      = { ":BufferWipeout", "Close buffer" }
