local plugins = require("my.plugins")

---@type blink.cmp.Config
local opts = {}

opts.cmdline = {
  enabled = true,
  keymap = {
    preset = "cmdline",
  },
}

opts.completion = {}
opts.completion.list = {
  max_items = 20,

  selection = {
    auto_insert = true,
  },

  cycle = {
    from_bottom = true,
    from_top = true,
  },
}

opts.completion.accept = {
  create_undo_point = true,

  auto_brackets = {
    enabled = true,
    default_brackets = { '(', ')' },
    kind_resolution = {
      enabled = true,
    },
    semantic_token_resolution = {
      enabled = true,
      -- How long to wait for semantic tokens to return before assuming no brackets should be added
      timeout_ms = 400,
    },
  },
}

opts.completion.documentation = {
  auto_show = true,
  auto_show_delay_ms = 500,
}

opts.completion.ghost_text = {
  enabled = false,
}



local km = require "my.keymap"
local Ctrl = km.Ctrl
local Tab = km.Tab
local Shift = km.Shift
local Enter = km.Enter

local disable = {}

opts.keymap = {
  preset = "enter",

  [Ctrl.Space] = { "show", "show_documentation", "hide_documentation" },
  [Ctrl.e]     = { "cancel" },
  [Ctrl.y]     = { "select_and_accept", "fallback" },

  [Ctrl.p]     = { "select_prev", "fallback" },
  [Ctrl.n]     = { "select_next", "fallback" },

  [Ctrl.b]     = { "scroll_documentation_up", "fallback" },
  [Ctrl.f]     = { "scroll_documentation_down", "fallback" },

  [Tab]        = { "snippet_forward", "fallback" },
  [Shift.Tab]  = { "snippet_backward", "fallback" },

  [km.Up]   = disable,
  [km.Down] = disable,
}


opts.appearance = {
  nerd_font_variant = "mono",
}

-- default list of enabled providers defined so that you can extend it
-- elsewhere in your config, without redefining it, via `opts_extend`
opts.sources = {
  default = { "lsp", "path", "snippets", "buffer" },
  providers = {},
}

if plugins.installed("blink-emoji.nvim") then
  opts.sources.providers.emoji = {
    name = "emoji",
    module = "blink-emoji",
    score_offset = 15,
    opts = { insert = true },
    enabled = true,
    should_show_items = true,
    min_keyword_length = 0,
  }
  table.insert(opts.sources.default, "emoji")
end

if plugins.installed("Kaiser-Yang/blink-cmp-git") then
  local filetypes = { "octo", "gitcommit", "markdown" }

  opts.sources.providers.git = {
    name = "git",
    module = "blink-cmp-git",
    enabled = function()
      return vim.tbl_contains(filetypes, vim.bo.filetype)
    end,
    should_show_items = true,
    min_keyword_length = 0,
  }
  table.insert(opts.sources.default, "git")
end

if plugins.installed("blink-nerdfont.nvim") then
  opts.sources.providers.nerdfont = {
    name = "Nerd Font Icon",
    module = "blink-nerdfont",
    score_offset = 15,
    opts = { insert = true },
    enabled = true,
    should_show_items = true,
    min_keyword_length = 0,
  }
  table.insert(opts.sources.default, "nerdfont")
end


opts.signature = {
  enabled = true,
}

opts.fuzzy = {
  implementation = "rust",
  use_frecency = true,
  use_proximity = true,
}

require("blink.cmp").setup(opts)
