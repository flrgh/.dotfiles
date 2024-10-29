-- don't configure or start lsp if vim is running in headless mode
if #vim.api.nvim_list_uis() == 0 then
  return
end

local mod = require 'my.utils.luamod'
local plugin = require "my.utils.plugin"
local fs = require "my.utils.fs"
local WS = require "my.workspace"

if not mod.exists("lspconfig") then
  return
end

local evt = require "my.event"

local lspconfig = require "lspconfig"

local executable = vim.fn.executable
local extend = vim.tbl_deep_extend
local is_empty = vim.tbl_isempty
local api = vim.api
local lsp = vim.lsp
local is_list = vim.islist
local jump_to_location = lsp.util.jump_to_location
local vim = vim

local function root_dir()
  return require("my.config.globals").workspace
end

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
    code_action         = lsp.buf.code_action,
    declaration         = lsp.buf.declaration,
    definition          = lsp.buf.definition,
    hover               = lsp.buf.hover,
    implementation      = lsp.buf.implementation,
    references          = lsp.buf.references,
    rename              = lsp.buf.rename,
    show_diagnostic     = vim.diagnostic.open_float,
    signature_help      = lsp.buf.signature_help,
    type_definition     = lsp.buf.type_definition,
  }

  if mod.exists("lspsaga") then
    local cmd = function(s)
      return ("<cmd>Lspsaga %s<CR>"):format(s)
    end

    maps.hover = cmd("hover_doc")
    maps.references = cmd("finder")
    maps.show_diagnostic = cmd("show_line_diagnostics")
    maps.next_diagnostic = cmd("diagnostic_jump_next")
    maps.prev_diagnostic = cmd("diagnostic_jump_prev")
  end

  if mod.exists("hover") then
    -- I like this better than lspsaga's hover_doc
    local hover = require("hover").hover
    local api = vim.api

    -- 1. press the key once to show the doc window
    -- 2. press the key a second time to change focus to the window
    -- https://github.com/lewis6991/hover.nvim/issues/49
    maps.hover = function()
      local hover_win = vim.b.hover_preview
      if hover_win and api.nvim_win_is_valid(hover_win) then
        api.nvim_set_current_win(hover_win)
      else
        return hover()
      end
    end
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

  ---@param client vim.lsp.Client
  ---@param buf    number
  function on_attach(client, buf)
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

      km.buf.nnoremap[Leader.vr]   = { maps.references, "[V]iew [R]eferences" }
    end

    vim.diagnostic.config({
      virtual_text = false,
    })

    api.nvim_set_option_value('tagfunc', 'v:lua.vim.lsp.tagfunc', { buf = buf })
    api.nvim_set_option_value('omnifunc', 'v:lua.vim.lsp.omnifunc', { buf = buf })
  end
end


---@type lsp.ClientCapabilities
local caps
do
  caps = lsp.protocol.make_client_capabilities()

  if mod.exists("cmp_nvim_lsp") then
    caps = require("cmp_nvim_lsp").default_capabilities(caps)
  end
end


local servers = {
  awk          = "awk_ls",
  bash         = "bashls",
  clang        = "clangd",
  dockerfile   = "dockerls",
  go           = "gopls",
  jinja        = "jinja_lsp",
  json         = "jsonls",
  lua          = "lua_ls",
  markdown     = "marksman",
  python       = "pyright",
  rust         = "rust_analyzer",

  --[[
    sql-language-server is completely unusable
  sql          = "sqlls",
  ]]--

  terraform    = "terraformls",
  yaml         = "yamlls",
  typescript   = "ts_ls",
  zig          = "zls",
}

if plugin.installed("rustaceanvim") then
  servers.rust = nil

  local rv = {
    server = {
      on_attach = on_attach,
    },
    default_settings = {},
  }

  if mod.exists("my.lsp.server.rust_analyzer") then
    local rust = require "my.lsp.server.rust_analyzer"
    if type(rust.init) == "function" then
      local conf = rust.init()
      rv.default_settings = conf.settings
    end
  end

  vim.g.rustaceanvim = extend("force", vim.g.rustaceanvim or {}, rv)
end

---@class my.lsp.hook
---
---@field init fun():lspconfig.Config
---@field on_attach fun(client:vim.lsp.Client, buf:integer)

---@type table<string, my.lsp.hook>
local hooks = {}


---@param lang string
---@param name string
local function setup_server(lang, name)
  local server = lspconfig[name]
  if not server then
    vim.notify("unknown LSP server: " .. name, vim.log.levels.WARN)
  end

  ---@type lspconfig.Config
  local conf = {
    log_level = 2,
    capabilities = caps,
  }

  local mod_name = "my.lsp.server." .. name
  mod.if_exists(mod_name, function(m)
    if type(m.init) == "function" then
      conf = extend("force", conf, m.init())
    end

    hooks[name] = m
  end)

  local cmd = conf.cmd
    or (server.document_config
    and server.document_config.default_config
    and server.document_config.default_config.cmd)

  if cmd and executable(cmd[1]) == 1 then
    server.setup(conf)
  end
end

for lang, server in pairs(servers) do
  setup_server(lang, server)
end

local group = vim.api.nvim_create_augroup("UserLSP", { clear = true })

vim.api.nvim_create_autocmd(evt.LspAttach, {
  desc  = "Setup LSP things whenever a new client is attached to the buffer",
  group = group,
  callback = function(e)
    local client = vim.lsp.get_client_by_id(e.data.client_id)
    on_attach(client, e.buf)

    local hook = hooks[client.name]

    if hook and type(hook.on_attach) == "function" then
      vim.schedule(function()
        hook.on_attach(client, e.buf)
      end)
    end
  end,
})

vim.api.nvim_create_user_command(
  "LspSettings",
  function(args)
    ---@param client vim.lsp.Client
    local function info(client)
      return {
        name = client.name,
        settings = client.settings or vim.NIL,
        workspace_folders = client.workspace_folders or vim.NIL,
      }
    end

    if args.fargs and #args.fargs == 1 then
      local name = args.fargs[1]

      for _, client in ipairs(lsp.get_clients()) do
        if client.name == name then
          vim.print(info(client).settings)
          return
        end
      end

      vim.notify("LSP client '" .. name .. "' not found")
      return
    end

    local result = {}
    for i, client in ipairs(lsp.get_clients()) do
      result[i] = info(client)
    end

    if #result > 1 then
      vim.print(result)

    elseif #result == 1 then
      vim.print(result[1])

    else
      vim.notify("No active LSP clients")
    end
  end,
  {
    desc = "Show settings for active LSP clients",
    nargs = "?",
    complete = function()
      local names = {}
      for i, client in ipairs(lsp.get_clients()) do
        names[i] = client.name
      end
      return names
    end,
  }
)

vim.api.nvim_create_user_command(
  "LspCapabilities",
  function(args)
    ---@param client vim.lsp.Client
    local function get_caps(client)
      return {
        name = client.name,
        client = client.capabilities,
        server = client.server_capabilities,
      }
    end

    local buf = require("string.buffer").new()

    ---@param t table|any
    ---@param label string
    ---@param lvl? integer
    local function display(t, label, lvl)
      local typ = type(t)
      lvl = lvl or 0
      if typ == "table" then
        display("...", label, lvl)
        for k, v in pairs(t) do
          display(v, tostring(k), lvl + 1)
        end

      else
        buf:putf("%s%s => %q\n", string.rep("  ", lvl), label, t)
      end
    end

    local function render(info)
      buf:putf("%s\n", info.name)
      display(info.client, "client")
      display(info.server, "server")
    end

    if args.fargs and #args.fargs == 1 then
      local name = args.fargs[1]

      for _, client in ipairs(lsp.get_clients()) do
        if client.name == name then
          render(get_caps(client))
          vim.print(buf:get())
          return
        end
      end

      vim.notify("LSP client '" .. name .. "' not found")
      return
    end

    local result = {}
    for i, client in ipairs(lsp.get_clients()) do
      result[i] = get_caps(client)
    end

    if #result > 1 then
      for _, info in ipairs(result) do
        render(info)
      end
      vim.print(buf:get())

    elseif #result == 1 then
      render(result[1])
      vim.print(buf:get())

    else
      vim.notify("No active LSP clients")
    end
  end,
  {
    desc = "Show capabilities for active LSP clients",
    nargs = "?",
    complete = function()
      local names = {}
      for i, client in ipairs(lsp.get_clients()) do
        names[i] = client.name
      end
      return names
    end,
  }
)

vim.api.nvim_create_autocmd('DiagnosticChanged', {
  callback = function(args)
    if not args.file then
      return

    elseif not fs.is_child(WS.dir, args.file) then
      return
    end

    local diagnostics = args.data.diagnostics
    local items = {}
    for _, elem in ipairs(diagnostics) do
      if elem.code == "undefined-doc-name"
        and elem.source
        and elem.source:find("Lua")
      then
        table.insert(items, elem)
      end
    end
    if #items > 0 then
      local names = {}
      local seen = {}
      vim.schedule(function()
        for _, item in ipairs(items) do
          local name = vim.api.nvim_buf_get_text(item.bufnr, item.lnum, item.col, item.end_lnum, item.end_col, { })
          name = name and name[1]
          if name and not seen[name] then
            seen[name] = true
            table.insert(names, name)
          end
        end
        if #names > 0 then
          require("my.lsp.server.lua_ls").find_type_defs(names)
        end
      end)
    end
  end,
})
