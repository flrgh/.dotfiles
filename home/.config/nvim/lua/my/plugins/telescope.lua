local km = require('my.keymap')
local actions = require "telescope.actions"

-- turn on line numbers for previewers
--
-- this is kind of buggy, but it's the best I can do for now
vim.cmd "autocmd User TelescopePreviewerLoaded setlocal number"

require('telescope').setup({
  pickers = {
    colorscheme = {
      enable_preview = true,
    },
  },

  defaults = {
    mappings = {
      i = {
        [km.Ctrl.j] = actions.move_selection_next,
        [km.Ctrl.k] = actions.move_selection_previous,
      },
    },

    layout_strategy = "flex",

    layout_config = {
      horizontal = {
        width = 0.95,
        height = 0.9,
        prompt_position = "bottom",
        preview_cutoff = 120,
      },

      vertical = {
        width = 0.9,
        height = 0.9,
        prompt_position = "bottom",
        preview_cutoff = 40,
      },

      center = {
        width = 0.9,
        height = 0.9,
        preview_cutoff = 40,
        prompt_position = "top",
      },

      cursor = {
        width = 0.9,
        height = 0.9,
        preview_cutoff = 40,
      },

      bottom_pane = {
        height = 25,
        prompt_position = "top",
      },
    },
  },
})
