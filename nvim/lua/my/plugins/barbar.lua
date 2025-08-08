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
  focus_on_close = "previous",
  maximum_padding = 4,
  maximum_length = 30,
  semantic_letters = true,
  no_name_title = nil,
  insert_at_end = true,
  insert_at_start = false,
})

local ev = require("my.event")

ev.on(ev.VimEnter)
  :group("user-barbar-keybinds")
  :pattern("*")
  :once(true)
  :desc("Create barbar buffer key bindings")
  :callback(function()
    local km = require "my.keymap"
    local Ctrl = km.Ctrl
    local Leader = km.Leader

    km.nnoremap(Ctrl.PageUp)
      :desc("Previous buffer [barbar]")
      :cmd("BufferPrevious")

    km.nnoremap(Ctrl.PageDown)
      :desc("Next buffer [barbar]")
      :cmd("BufferNext")

    km.nnoremap(Leader.w)
      :desc("Close buffer [barbar]")
      :cmd("BufferWipeout")

    km.nnoremap(Ctrl.Shift.PageUp)
      :desc("Move buffer to the left")
      :cmd("BufferMovePrevious")

    km.nnoremap(Ctrl.Shift.PageDown)
      :desc("Move buffer to the right")
      :cmd("BufferMoveNext")
  end)
