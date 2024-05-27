-- don't configure or start lsp if vim is running in headless mode
if #vim.api.nvim_list_uis() == 0 then
  return
end

local mod = require 'my.utils.module'

if not mod.exists('lspconfig') then
  return
end

local lspconfig = require "lspconfig"

local executable = vim.fn.executable
local extend = vim.tbl_deep_extend
local is_empty = vim.tbl_isempty
local api = vim.api
local lsp = vim.lsp
local is_list = vim.islist
local jump_to_location = lsp.util.jump_to_location
local vim = vim


vim.lsp.handlers["textDocument/definition"] = function(_, result)
  if not result or is_empty(result) then
    print "[LSP] Could not find definition"
    return
  end

  if is_list(result) then
    jump_to_location(result[1], "utf-8")
  else
    jump_to_location(result, "utf-8")
  end
end

local on_attach
do
  ---@type table<string, function|string>
  local maps = {
    rename              = lsp.buf.rename,
    references          = lsp.buf.references,
    code_action         = lsp.buf.code_action,
    declaration         = lsp.buf.declaration,
    definition          = lsp.buf.definition,
    type_definition     = lsp.buf.type_definition,
    signature_help      = lsp.buf.signature_help,
    hover               = lsp.buf.hover,
    implementation      = lsp.buf.implementation,
    show_diagnostic     = vim.diagnostic.open_float,
  }

  if mod.exists("hover") then
    maps.hover = require("hover").hover

  elseif mod.exists("lspsaga") then
    local cmd = function(s)
      return ("<cmd>Lspsaga %s<CR>"):format(s)
    end

    maps.hover = cmd("hover_doc")
    maps.code_action = cmd("code_action")
    maps.range_code_action = cmd("range_code_action")
    maps.show_diagnostic = cmd("show_line_diagnostics")
    maps.next_diagnostic = cmd("diagnostic_jump_next")
    maps.prev_diagnostic = cmd("diagnostic_jump_prev")
  end

  do
    maps.toggle_diagnostics = function()
      if vim.diagnostic.is_enabled() then
        vim.notify("disabling diagnostics")
        vim.diagnostic.enable(false)
      else
        vim.notify("enabling diagnostics")
        vim.diagnostic.enable(true)
      end
    end
  end

  do
    maps.toggle_inlay_hints = function()
      ---@type notify.Options
      local opts = {
        hide_from_history = true,
      }

      if vim.lsp.inlay_hint.is_enabled() then
        vim.notify("disabling inlay hints", nil, opts)
        vim.lsp.inlay_hint.enable(false)
      else
        vim.notify("enabling inlay hints", nil, opts)
        vim.lsp.inlay_hint.enable(true)
      end
    end
  end

  ---@param buf    number
  function on_attach(_, buf)
    -- set up key bindings
    do
      local km = require('my.keymap')

      km.buf.nnoremap.gD          = { maps.declaration, "Go to declaration" }
      km.buf.nnoremap.gd          = { maps.type_definition, "Go to type definition" }
      km.buf.nnoremap.gi          = { maps.implementation, "Go to implementation" }

      km.buf.nnoremap.K           = { maps.hover, "Hover info" }

      local Leader = km.Leader
      km.buf.nnoremap[Leader.ca]   = { maps.code_action, "Code action" }
      km.buf.vnoremap[Leader.ca]   = { maps.range_code_action, "Code action (ranged)" }

      km.buf.nnoremap[Leader.nd]   = { maps.next_diagnostic, "Next diagnostic" }
      km.buf.nnoremap[Leader.pd]   = { maps.prev_diagnostic, "Previous diagnostic" }
      km.buf.nnoremap[Leader.sd]   = { maps.show_diagnostic, "Show diagnistics" }
      km.buf.nnoremap[Leader.td]   = { maps.toggle_diagnostics, "Toggle diagnistics" }
      km.buf.nnoremap[Leader.ti]   = { maps.toggle_inlay_hints, "Toggle inlay hints" }

      km.buf.nnoremap[Leader.rn]   = { maps.rename, "Rename variable" }
    end

    vim.diagnostic.config({
      virtual_text = false,
    })

    api.nvim_set_option_value('tagfunc', 'v:lua.vim.lsp.tagfunc', { buf = buf })
    api.nvim_set_option_value('omnifunc', 'v:lua.vim.lsp.omnifunc', { buf = buf })
  end
end


local caps
do
  caps = lsp.protocol.make_client_capabilities()

  mod.if_exists('cmp_nvim_lsp', function(cmp_nvim_lsp)
    caps = cmp_nvim_lsp.default_capabilities(caps)
  end)
end


local servers = {
  awk          = "awk_ls",
  bash         = "bashls",
  clangd       = "clangd",
  dockerfile   = "dockerls",
  go           = "gopls",
  json         = "jsonls",
  lua          = "lua_ls",
  markdown     = "marksman",
  python       = "pyright",
  rust         = "rust_analyzer",

  --[[
    sql-language-server is completely unusable
  sql          = "sqlls",
  ]]--

  teal         = "tealls",
  terraform    = "terraformls",
  yaml         = "yamlls",
  typescript   = "tsserver",
  zig          = "zls",
}

for lang, server in pairs(servers) do
  ---@type lspconfig.Config
  local conf = {
    log_level = 2,
    on_attach = on_attach,
  }

  local mod_name = "my.lsp." .. lang
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
    conf.workspace = require("my.config.globals").workspace
    conf.root_dir = function() return conf.workspace end
    conf.cmd = conf.cmd
      or lspconfig[server]
      and lspconfig[server].document_config
      and lspconfig[server].document_config.default_config
      and lspconfig[server].document_config.default_config.cmd

    if conf.cmd and executable(conf.cmd[1]) == 1 then
      lspconfig[server].setup(conf)
    end
  end
end
