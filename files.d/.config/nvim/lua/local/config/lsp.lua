-- don't configure or start lsp if vim is running in headless mode
if #vim.api.nvim_list_uis() == 0 then
  return
end

local mod = require 'local.module'

local lsp = require 'lspconfig'

---@param client table
---@param buf    number
local function on_attach(client, buf)
  -- set up key bindings
  do
    local km = require('local.keymap')

    km.nnoremap.ctrl['-]'] = km.lsp.definition
    km.nnoremap.gD = km.lsp.declaration
    km.nnoremap.gd = km.lsp.definition
    km.nnoremap.K  = km.lsp.hover
  end

  vim.api.nvim_buf_set_option(buf, 'omnifunc', 'v:lua.vim.lsp.omnifunc')

  mod.if_exists('lsp-status', function(status)
    status.on_attach(client, buf)
  end)
end

local caps = vim.lsp.protocol.make_client_capabilities()

mod.if_exists('cmp_nvim_lsp', function(cmp_nvim_lsp)
  caps = cmp_nvim_lsp.update_capabilities(caps)
end)

local servers = {
  bash      = "bashls",
  go        = "gopls",
  json      = "jsonls",
  lua       = "sumneko_lua",
  python    = "pyright",
  sql       = "sqlls",
  teal      = "tealls",
  terraform = "terraformls",
  yaml      = "yamlls",
}

for lang, server in pairs(servers) do
  local conf = {
    log_level = 2,
    on_attach = on_attach,
  }

  local mod_name = "local.lsp." .. lang
  mod.if_exists(mod_name, function(m)
    conf.settings = m.settings
    conf.cmd = m.cmd
  end)

	conf.cmd = conf.cmd
    or lsp[server]
    and lsp[server].document_config
    and lsp[server].document_config.default_config
    and lsp[server].document_config.default_config.cmd

  if conf.cmd and vim.fn.executable(conf.cmd[1]) == 1 then
    lsp[server].setup(conf)
  end
end

mod.if_exists('lsp-status', function(status)
  status.register_progress()
end)
