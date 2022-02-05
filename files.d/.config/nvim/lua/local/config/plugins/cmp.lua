local _M = {}

local mod = require 'local.module'
local km = require 'local.keymap'
local g = require "local.config.globals"

---@return table<any, cmp.Mapping>
local function mapping(cmp)
  return {
    -- replace ctrl+n/ctrl+p with ctrl+j/ctrl+k
    [km.Ctrl.j] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert }),
    [km.Ctrl.k] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }),
    [km.Ctrl.n] = cmp.config.disable,
    [km.Ctrl.p] = cmp.config.disable,

    -- explicitly invoke completion
    [km.Ctrl.Space] = cmp.mapping.complete(),

    [km.Ctrl.e] = cmp.mapping.close(),

    [km.Enter] = cmp.mapping.confirm {
      behavior = cmp.ConfirmBehavior.Replace,
      select = true,
    },

    [km.Tab] = function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      else
        fallback()
      end
    end,
    [km.S_Tab] = function(fallback)
      if cmp.visible() then
        cmp.select_prev_item()
      else
        fallback()
      end
    end,
  }
end

---@return cmp.SourceConfig[]
local function sources(cmp)
  local get_cwd
  do
    local ws = g.workspace or os.getenv("PWD")
    if ws then
      get_cwd = function() return ws end
    end
  end

  local sources = {
    { name = 'nvim_lua' },
    { name = 'nvim_lsp' },
    { name = 'buffer' },
    { name = 'path', option = { get_cwd = get_cwd } },
    { name = 'calc' },
    { name = 'emoji' },
  }

  if mod.exists("luasnip") then
    table.insert(sources, { name = "luasnip" })
  end

  return sources
end

---@return cmp.SnippetConfig
local function snippet()
  if mod.exists("luasnip") then
    return {
      expand = function(opts)
        require('luasnip').lsp_expand(opts.body)
      end,
    }
  end
end

---@return cmp.FormattingConfig
local function formatting(cmp)
  mod.if_exists("lspkind", function(lspkind)
    return {
      format = lspkind.cmp_format({
        with_text = true,
        mode = 'symbol_text',
        menu = {
          buffer   = "[buf]",
          nvim_lsp = "[lsp]",
          nvim_lua = "[nvim]",
          path     = "[path]",
          luasnip  = "[snip]",
        },
      })
    }
  end)
end

---@return cmp.ExperimentalConfig
local function experimental()
  return {
    native_menu = false,
    ghost_text = true,
  }
end

function _M.setup()
  if not mod.exists('cmp') then
    return
  end

  local cmp = require 'cmp'

  -- Set completeopt to have a better completion experience
  vim.opt.completeopt = { "menu", "menuone", "noselect" }

  -- Don't show the dumb matching stuff.
  vim.opt.shortmess:append "c"

  cmp.setup({
    mapping      = mapping(cmp),
    sources      = sources(cmp),
    snippet      = snippet(cmp),
    formatting   = formatting(cmp),
    experimental = experimental(cmp),
  })
end

return _M
