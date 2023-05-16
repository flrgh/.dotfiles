local _M = {}

local mod = require 'local.module'

if not mod.exists('cmp') then
  return { setup = function() end }
end

local cmp = require 'cmp'

local km = require 'local.keymap'
local g = require "local.config.globals"

---@return table<any, cmp.Mapping>
local function mapping()
  return cmp.mapping.preset.insert {
    -- replace ctrl+n/ctrl+p with ctrl+j/ctrl+k
    [km.Ctrl.j] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert }),
    [km.Ctrl.k] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }),
    [km.Ctrl.n] = cmp.config.disable,
    [km.Ctrl.p] = cmp.config.disable,

    -- explicitly invoke completion
    [km.Ctrl.Space] = cmp.mapping.complete,

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

local function sources()
  local get_cwd
  do
    local ws = g.workspace or os.getenv("PWD")
    if ws then
      get_cwd = function() return ws end
    end
  end

  local src = {
    { name = 'nvim_lua' },
    { name = 'nvim_lsp' },
    { name = 'nvim_lsp_signature_help' },
    { name = 'treesitter' },
    { name = 'buffer' },
    { name = 'path', option = { get_cwd = get_cwd } },
    { name = 'calc' },
    { name = 'emoji' },
    { name = 'copilot' },
  }

  for i = 1, #src do
    src[i].entry_filter = entry_filter
  end

  return cmp.config.sources(src)
end

local function snippet()
  if mod.exists("luasnip") then
    return {
      expand = function(opts)
        require("luasnip").lsp_expand(opts.body)
      end,
    }
  end
end

---@return cmp.FormattingConfig|nil
local function formatting(_)
  if not mod.exists("lspkind") then
    return
  end

  local lspkind = require "lspkind"
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
end

---@return cmp.ExperimentalConfig
local function experimental()
  ---@type cmp.ExperimentalConfig
  return {
    native_menu = false,
    ghost_text = true,
  }
end

local function window()
  ---@type cmp.WindowConfig
  local w = {}
  w.completion = cmp.config.window.bordered()
  w.documentation = cmp.config.window.bordered()
  return w
end


local function sorting()
  return require("cmp.config.default")().sorting
end


---@param extend? cmp.ConfigSchema|fun(cfg: cmp.ConfigSchema):cmp.ConfigSchema
---@return cmp.ConfigSchema
local function defaults(extend)
  ---@type cmp.ConfigSchema
  local cfg = {}

  cfg.mapping      = mapping()
  cfg.sources      = sources()
  cfg.snippet      = snippet()
  cfg.formatting   = formatting()
  cfg.experimental = experimental()
  cfg.window       = window()
  cfg.sorting      = sorting()

  local typ = type(extend)
  if typ == "function" then
    cfg = extend(cfg)

  elseif typ == "table" then
    cfg = vim.tbl_deep_extend({ "force" }, cfg, extend)
  end

  return cfg
end

function _M.setup()
  -- Set completeopt to have a better completion experience
  vim.opt.completeopt = { "menu", "menuone", "noselect" }

  -- Don't show the dumb matching stuff.
  vim.opt.shortmess:append "c"

  cmp.setup(defaults())

  cmp.setup.cmdline(':', {
    mapping = cmp.mapping.preset.cmdline(),
    sources = cmp.config.sources({
      { name = 'path' },
      { name = 'cmdline' },
    })
  })
end

return _M
