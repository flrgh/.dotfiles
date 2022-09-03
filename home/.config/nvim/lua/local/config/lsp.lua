-- don't configure or start lsp if vim is running in headless mode
if #vim.api.nvim_list_uis() == 0 then
  return
end

local mod = require 'local.module'

if not mod.exists('lspconfig') then
  return
end

local lspconfig = require 'lspconfig'

local extend = vim.tbl_deep_extend
local vim = vim
local api = vim.api
local lsp = vim.lsp
local is_list = vim.tbl_islist


vim.lsp.handlers["textDocument/definition"] = function(_, result)
  if not result or vim.tbl_isempty(result) then
    print "[LSP] Could not find definition"
    return
  end

  if is_list(result) then
    lsp.util.jump_to_location(result[1], "utf-8")
  else
    lsp.util.jump_to_location(result, "utf-8")
  end
end


local on_attach
do
  ---@type table<string, function>
  local maps = {
      declaration = lsp.buf.declaration,
      definition  = lsp.buf.definition,
      hover       = lsp.buf.hover,
      code_action = lsp.buf.code_action,
      show_diagnostic  = vim.diagnostic.open_float,
  }

  if mod.exists("lspsaga") then
    local saga = require "lspsaga"
    local cmd = function(s)
      return ("<cmd>Lspsaga %s<CR>"):format(s)
    end

    maps.hover = cmd("hover_doc")
    maps.code_action = cmd("code_action")
    maps.range_code_action = cmd("range_code_action")
    maps.show_diagnostic = cmd("show_line_diagnostics")
    maps.next_diagnostic = cmd("diagnostic_jump_next")
    maps.prev_diagnostic = cmd("diagnostic_jump_prev")


  elseif mod.exists("hover") then
    maps.hover = require("hover").hover
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
  function on_attach(_, buf)
    -- set up key bindings
    do
      local km = require('local.keymap')

      -- superceded by vim.lsp.tagfunc
      --km.nnoremap.ctrl[']'] = km.lsp.definition

      km.buf.nnoremap.gD = maps.declaration
      km.buf.nnoremap.gd = maps.definition
      km.buf.nnoremap.K  = maps.hover
      km.buf.nnoremap.leader.td = maps.toggle_diagnostics
      km.buf.nnoremap.leader.sd = maps.show_diagnostic
      km.buf.nnoremap.leader.nd = maps.next_diagnostic
      km.buf.nnoremap.leader.pd = maps.prev_diagnostic
      km.buf.nnoremap.leader.ca = maps.code_action
      km.buf.vnoremap.leader.ca = maps.range_code_action
    end

    vim.diagnostic.config({
      virtual_text = false,
    })

    api.nvim_buf_set_option(buf, 'tagfunc', 'v:lua.vim.lsp.tagfunc')
    api.nvim_buf_set_option(buf, 'omnifunc', 'v:lua.vim.lsp.omnifunc')
  end
end


local caps
do
  caps = lsp.protocol.make_client_capabilities()

  mod.if_exists('cmp_nvim_lsp', function(cmp_nvim_lsp)
    caps = cmp_nvim_lsp.update_capabilities(caps)
  end)
end


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
