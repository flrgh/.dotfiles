local _M = {}

local mod = require "my.utils.luamod"
local plugin = require "my.utils.plugin"
local km = require("my.keymap")
local proto = require("vim.lsp.protocol")

local executable = vim.fn.executable
local is_empty = vim.tbl_isempty
local api = vim.api
local lsp = vim.lsp
local is_list = vim.islist
local vim = vim
local textDocumentDefinition = proto.Methods.textDocument_definition

local LOG_LEVEL = vim.log.levels.WARN
local KEYMAP_TAG = "global-lsp-keymaps"

local SERVERS = {
  "awk_ls",
  "bashls",
  "clangd",
  "docker_compose_language_service",
  "dockerls",
  "gh_actions_ls",
  "gopls",
  "jinja_lsp",
  "jsonls",
  "lua_ls",
  "marksman",
  --[[
  unmaintained
  "nginx_language_server",
  --]]
  "pyright",
  "rust_analyzer",
  "systemd_ls",

  --[[
  sql-language-server is completely unusable
  "sqlls",
  ]]--

  "terraformls",
  "yamlls",
  "ts_ls",
  "zls",
}


local function setup_goto_definition()
  local jump_to_location = lsp.util.jump_to_location

  lsp.handlers[textDocumentDefinition] = function(_, result)
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
end


---@type function
local attach_keymaps
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

  local configured = false

  ---@return table<string, function|string>
  local function configure()
    if configured then
      return maps
    end

    configured = true

    if mod.exists("lspsaga") then
      local cmd = function(s)
        return ("<cmd>Lspsaga %s<CR>"):format(s)
      end

      maps.hover = cmd("hover_doc")
      maps.references = cmd("finder")

      -- FIXME: re-enable this
      -- https://github.com/nvimdev/lspsaga.nvim/issues/1502
      -- maps.show_diagnostic = cmd("show_line_diagnostics")

      maps.next_diagnostic = cmd("diagnostic_jump_next")
      maps.prev_diagnostic = cmd("diagnostic_jump_prev")
    end

    if mod.exists("hover") then
      -- I like this better than lspsaga's hover_doc
      local hover = require("hover").hover

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

    return maps
  end

  local Leader = km.Leader

  function attach_keymaps()
    configure()

    -- set up key bindings
    km.buf.nnoremap.gD          = { maps.declaration, "Go to declaration", KEYMAP_TAG }
    km.buf.nnoremap.gd          = { maps.type_definition, "Go to type definition", KEYMAP_TAG }
    km.buf.nnoremap.gi          = { maps.implementation, "Go to implementation", KEYMAP_TAG }

    km.buf.nnoremap.K           = { maps.hover, "Hover info", KEYMAP_TAG }

    km.buf.nnoremap[Leader.ca]   = { maps.code_action, "Code action", KEYMAP_TAG }
    km.buf.vnoremap[Leader.ca]   = { maps.range_code_action, "Code action (ranged)", KEYMAP_TAG }

    km.buf.nnoremap[Leader.nd]   = { maps.next_diagnostic, "Next diagnostic", KEYMAP_TAG }
    km.buf.nnoremap[Leader.pd]   = { maps.prev_diagnostic, "Previous diagnostic", KEYMAP_TAG }
    km.buf.nnoremap[Leader.sd]   = { maps.show_diagnostic, "Show diagnistics", KEYMAP_TAG }
    km.buf.nnoremap[Leader.td]   = { maps.toggle_diagnostics, "Toggle diagnistics", KEYMAP_TAG }
    km.buf.nnoremap[Leader.ti]   = { maps.toggle_inlay_hints, "Toggle inlay hints", KEYMAP_TAG }

    km.buf.nnoremap[Leader.rn]   = { maps.rename, "Rename variable", KEYMAP_TAG }

    km.buf.nnoremap[Leader.vr]   = { maps.references, "[V]iew [R]eferences", KEYMAP_TAG }
  end
end



---@param _client_id number
---@param buf    number
function _M.on_attach(_client_id, buf)
  attach_keymaps()

  setup_goto_definition()

  vim.diagnostic.config({
    virtual_text = false,
  })

  vim.bo[buf].tagfunc = "v:lua.vim.lsp.tagfunc"
  vim.bo[buf].omnifunc = "v:lua.vim.lsp.omnifunc"
end


---@param client_id number
---@param buf    number
function _M.on_detach(client_id, buf)
  local clients = lsp.get_clients({ bufnr = buf })

  -- no more connected clients (or this was the last one)
  if not clients
    or #clients == 0
    or (#clients == 1 and clients[1].id == client_id)
  then
    -- teardown for midterms
    vim.bo[buf].tagfunc = nil
    vim.bo[buf].omnifunc = nil
    km.remove_by_tag(KEYMAP_TAG)
  end
end


---@return lsp.ClientCapabilities
local function make_capabilities()
  local caps = lsp.protocol.make_client_capabilities()

  if plugin.installed("blink.cmp") then
    local overrides = nil
    local include_nvim_defaults = true
    caps = require("blink.cmp").get_lsp_capabilities(overrides, include_nvim_defaults)

  elseif plugin.installed("nvim-cmp") then
    caps = require("cmp_nvim_lsp").default_capabilities(caps)
  end

  return caps
end


---@param name string
local function setup_server(name)
  local conf = lsp.config[name]
  if not conf then
    vim.notify("unknown LSP server: " .. name, vim.log.levels.WARN)
    return
  end

  local cmd = conf.cmd
  if cmd and executable(cmd[1]) == 1 then
    lsp.config(name, conf)
    lsp.enable(name)
  end
end


function _M.init()
  -- don't configure or start lsp if vim is running in headless mode
  if #api.nvim_list_uis() == 0 then
    return
  end

  if not plugin.installed("nvim-lspconfig") then
    vim.notify("nvim-lspconfig is not installed, some things might not work",
               vim.log.levels.WARN)
  end

  require("lspconfig")

  local const = require("my.constants")
  if const.lsp_debug then
    LOG_LEVEL = const.lsp_log_level
    require("my.lsp.logger").init()
  end
  vim.lsp.set_log_level(LOG_LEVEL)

  lsp.config("*", {
    capabilities = make_capabilities(),
    log_level = LOG_LEVEL,
  })

  for _, server in ipairs(SERVERS) do
    setup_server(server)
  end
end


return _M
