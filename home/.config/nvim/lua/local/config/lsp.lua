-- don't configure or start lsp if vim is running in headless mode
if #vim.api.nvim_list_uis() == 0 then
  return
end

local mod = require 'local.module'

if not mod.exists('lspconfig') then
  return
end

local extend = vim.tbl_deep_extend

vim.lsp.handlers["textDocument/definition"] = function(_, result)
  if not result or vim.tbl_isempty(result) then
    print "[LSP] Could not find definition"
    return
  end

  if vim.tbl_islist(result) then
    vim.lsp.util.jump_to_location(result[1], "utf-8")
  else
    vim.lsp.util.jump_to_location(result, "utf-8")
  end
end


local lspconfig = require 'lspconfig'

---@type table<string, function>
local maps = {
    declaration = vim.lsp.buf.declaration,
    definition = vim.lsp.buf.definition,
    hover = vim.lsp.buf.hover,
}

if mod.exists("hover") then
  maps.hover = require("hover").hover

elseif mod.exists("lspsaga") then
  maps.hover = require("lspsaga.hover").render_hover_doc
end

do
  local enabled = true
  maps.toggle_diagnostics = function()
    if enabled then
      vim.notify("disabling diagnostics")
      vim.diagnostic.disable()
      enabled = false
    else
      vim.notify("enabling diagnostics")
      vim.diagnostic.enable()
      enabled = true
    end
  end
end

---@param buf    number
local function on_attach(_, buf)
  -- set up key bindings
  do
    local km = require('local.keymap')

    -- superceded by vim.lsp.tagfunc
    --km.nnoremap.ctrl[']'] = km.lsp.definition

    km.buf.nnoremap.gD = maps.declaration
    km.buf.nnoremap.gd = maps.definition
    km.buf.nnoremap.K  = maps.hover
    km.buf.nnoremap.leader.td = maps.toggle_diagnostics
  end

  vim.api.nvim_buf_set_option(buf, 'tagfunc', 'v:lua.vim.lsp.tagfunc')
  vim.api.nvim_buf_set_option(buf, 'omnifunc', 'v:lua.vim.lsp.omnifunc')
end

local caps = vim.lsp.protocol.make_client_capabilities()

mod.if_exists('cmp_nvim_lsp', function(cmp_nvim_lsp)
  caps = cmp_nvim_lsp.update_capabilities(caps)
end)

local servers = {
  awk          = "awk_ls",
  bash         = "bashls",
  clangd       = "clangd",
  dockerfile   = "dockerls",
  go           = "gopls",
  json         = "jsonls",
  lua          = "sumneko_lua",
  markdown     = "marksman",
  python       = "pyright",
  rust         = "rust_analyzer",
  sql          = "sqlls",
  teal         = "tealls",
  terraform    = "terraformls",
  yaml         = "yamlls",
}

for lang, server in pairs(servers) do
  local conf = {
    log_level = 2,
    on_attach = on_attach,
  }

  local mod_name = "local.lsp." .. lang
  local setup = true
  mod.if_exists(mod_name, function(m)
    if type(m) == "table" then
      conf = extend("force", conf, m)

    elseif type(m) == "function" then
      setup = false
      m(conf)
    end
  end)

  if setup then
    conf.cmd = conf.cmd
      or lspconfig[server]
      and lspconfig[server].document_config
      and lspconfig[server].document_config.default_config
      and lspconfig[server].document_config.default_config.cmd

    if conf.cmd and vim.fn.executable(conf.cmd[1]) == 1 then
      lspconfig[server].setup(conf)
    end
  end
end
