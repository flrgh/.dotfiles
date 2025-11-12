local mod = require("my.std.luamod")

if not mod.exists("cmp") then
  return
end

local lspkind
if mod.exists("lspkind") then
  lspkind = require "lspkind"
  lspkind.init({})
end

---@module 'cmp'
local cmp = require("cmp")
local km = require("my.keymap")
local env = require("my.env")
local lls_types = require("my.cmp.source.lua_ls_types")

local Ctrl = km.Ctrl
local Tab = km.Tab
local Shift = km.Shift
local Enter = km.Enter

---@type cmp.ConfigSchema
local config = {}

do
  config.mapping = {
    [Ctrl.n] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert }),
    [Ctrl.p] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }),

    -- explicitly invoke completion
    [Ctrl.Space] = cmp.mapping.complete(),

    [Ctrl.e] = cmp.mapping.abort(),

    -- https://github.com/hrsh7th/nvim-cmp/wiki/Example-mappings#safely-select-entries-with-cr
    [Enter] = cmp.mapping({
      i = function(fallback)
        if cmp.visible() and cmp.get_active_entry() then
          cmp.confirm({ behavior = cmp.ConfirmBehavior.Replace, select = false })
        else
          fallback()
        end
      end,
      s = cmp.mapping.confirm({ select = true }),
    }),

    [Tab] = cmp.config.disable,
    [Shift.Tab] = cmp.config.disable,
  }
end

do
  local function get_cwd()
    return env.workspace and env.workspace.dir or env.cwd
  end

  cmp.register_source(lls_types.NAME, lls_types.new())

  -- https://github.com/hrsh7th/nvim-cmp/wiki/List-of-sources
  local sources = {
    -- use nvim lua API as a source
    -- https://github.com/hrsh7th/cmp-nvim-lua
    { name = "nvim_lua" },

    -- Complete from LSP
    -- https://github.com/hrsh7th/cmp-nvim-lsp
    { name = "nvim_lsp" },

    -- LSP, displays function signature
    -- https://github.com/hrsh7th/cmp-nvim-lsp-signature-help
    { name = "nvim_lsp_signature_help" },

    -- https://github.com/hrsh7th/cmp-nvim-lsp-document-symbol
    { name = "nvim_lsp_signature_help" },

    -- Complete from Treesitter nodes
    -- https://github.com/ray-x/cmp-treesitter
    { name = "treesitter" },

    -- Complete from text/words in the current buffer
    --
    -- TODO: maybe disable for large buffers
    --
    -- https://github.com/hrsh7th/cmp-buffer
    { name = "buffer", priority = 50 },

    -- Complete paths
    --
    -- Our custom `get_cwd` function causes it to complete from the workspace
    -- root instead of the parent directory of the current file.
    --
    -- https://github.com/hrsh7th/cmp-path
    { name = "path", option = { get_cwd = get_cwd } },

    -- Evalutes const mathematical expressions
    -- https://github.com/hrsh7th/cmp-calc
    { name = "calc" },

    -- Emoji
    -- https://github.com/hrsh7th/cmp-emoji
    { name = "emoji" },

    { name = "copilot", priority = 50 },

    { name = lls_types.NAME },
  }

  ---@param entry cmp.Entry
  ---@param ctx cmp.Context
  ---@return boolean
  local function entry_filter(entry, ctx)
    -- 1. filter out rust snippets
    if entry.completion_item.kind == 15 and -- snippet
      entry.source.name == "nvim_lsp" and
      ctx.filetype == "rust"
    then
      return false
    end

    return true
  end

  for i = 1, #sources do
    sources[i].priority = sources[i].priority or 100
    sources[i].entry_filter = entry_filter
  end

  config.sources = cmp.config.sources(sources)
end

if mod.exists("luasnip") then
  config.snippet = {
    expand = function(opts)
      require("luasnip").lsp_expand(opts.body)
    end,
  }
end

if lspkind then
  config.formatting = {
    format = lspkind.cmp_format({
      with_text = true,
      mode = 'symbol_text',
      menu = {
        buffer   = "[buf]",
        nvim_lsp = "[lsp]",
        nvim_lua = "[nvim]",
        path     = "[path]",
        luasnip  = "[snip]",
        [lls_types.NAME] = "[type]",
      },
    })
  }
end

config.experimental = {
  native_menu = false,
  ghost_text  = true,
}

config.window = {
  completion    = cmp.config.window.bordered(),
  documentation = cmp.config.window.bordered(),
}

config.sorting = require("cmp.config.default")().sorting

-- Set completeopt to have a better completion experience
vim.opt.completeopt = { "menu", "menuone", "noselect" }

-- Don't show the dumb matching stuff.
vim.opt.shortmess:append "c"

cmp.setup(config)

cmp.setup.cmdline(':', {
  mapping = cmp.mapping.preset.cmdline(),
  sources = cmp.config.sources({
    { name = 'path' },
    { name = 'cmdline' },
  }),
  matching = { disallow_symbol_nonprefix_matching = false },
})
