local km = require "my.keymap"
local actions = require "telescope.actions"
local plugin = require "my.utils.plugin"
local const = require "my.constants"

-- turn on line numbers for previewers
--
-- this is kind of buggy, but it's the best I can do for now
vim.cmd "autocmd User TelescopePreviewerLoaded setlocal number"

local fzf
if plugin.installed("telescope-fzf-native.nvim") then
  fzf = {
    fuzzy = true,                     -- false will only do exact matching
    override_generic_sorter = true,   -- override the generic sorter
    override_file_sorter = true,      -- override the file sorter
    case_mode = "smart_case",         -- or "ignore_case" or "respect_case"
                                      -- the default case_mode is "smart_case"
  }
end

local ts = require "telescope"

ts.setup({
  extensions = {
    fzf = fzf,
  },

  pickers = {
    colorscheme = {
      enable_preview = true,
    },

    find_files = {
      find_command = {
        "fd",
        "--type", "f",
        "--color", "never",
        "--hidden"
      },
    },

    live_grep = {
      additional_args = {
        "--hidden",
        "--glob", "!**/.git/*",
      },
    },

    grep_string = {
      additional_args = {
        "--hidden",
        "--glob", "!**/.git/*",
      },
    },
  },

  defaults = {
    mappings = {
      i = {
        [km.Ctrl.j] = actions.move_selection_next,
        [km.Ctrl.k] = actions.move_selection_previous,
        [km.Ctrl.n] = actions.move_selection_next,
        [km.Ctrl.p] = actions.move_selection_previous,
        [km.Escape] = actions.close,

        [km.Ctrl.y] = actions.preview_scrolling_up,
        [km.Ctrl.e] = actions.preview_scrolling_down,

        -- unbind default <C-u> behavior so it acts like readline instead
        [km.Ctrl.u] = false,
      },
    },

    layout_strategy = "flex",

    layout_config = {
      horizontal = {
        anchor = "CENTER",
        width = 0.9,
        height = 0.9,
        prompt_position = "bottom",
        preview_cutoff = 120,
        preview_width = 0.5,
      },

      vertical = {
        anchor = "CENTER",
        width = 0.9,
        height = 0.95,
        prompt_position = "bottom",
        preview_cutoff = 40,
      },

      bottom_pane = {
        height = 25,
        prompt_position = "top",
      },
    },
  },
})

if fzf then
  ts.load_extension('fzf')
end

local Ctrl = km.Ctrl
local Leader = km.Leader
local nnoremap = km.nnoremap

nnoremap(Ctrl.p)
  :desc("Fuzzy-find git-files w/ telescope")
  :cmd("Telescope git_files")

nnoremap(Leader.rg)
  :desc("Live Grep (rg)")
  :cmd("Telescope live_grep")

nnoremap(Leader.pf)
  :desc("Find neovim [p]lugin [f]iles")
  :callback(function()
    require("telescope.builtin").find_files({
      cwd = const.nvim.plugins,
    })
  end)

nnoremap(Leader.prg)
  :desc("[p]lugin [f]ile [g]rep")
  :callback(function()
    require("telescope.builtin").live_grep({
      cwd = const.nvim.plugins,
    })
  end)

nnoremap(Leader.vf)
  :desc("Find neovim runtime files")
  :callback(function()
    require("telescope.builtin").find_files({
      cwd = const.nvim.runtime,
    })
  end)

nnoremap(Leader.b)
  :desc("Search buffers")
  :cmd("Telescope buffers")
