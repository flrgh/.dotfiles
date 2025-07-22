local _M = {}

local plugin = require "my.utils.plugin"
local km = require("my.keymap")
local const = require("my.constants")

local executable = vim.fn.executable
local api = vim.api
local lsp = vim.lsp
local vim = vim
local byte = string.byte
local sort = table.sort

local LOG_LEVEL = vim.log.levels.WARN
local KEYMAP_TAG = "global-lsp-keymaps"
local SLASH = byte("/")

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


---@type function
local attach_keymaps
do
  ---@type table<string, function|string>
  local maps = {
    code_action         = lsp.buf.code_action,
    declaration         = lsp.buf.declaration,
    definition          = lsp.buf.definition,
    hover               = function()
      return lsp.buf.hover({
        border = "rounded",
      })
    end,
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

    if plugin.installed("lspsaga.nvim") then
      local cmd = function(s)
        return ("<cmd>Lspsaga %s<CR>"):format(s)
      end

      maps.references = cmd("finder")

      -- FIXME: re-enable this
      -- https://github.com/nvimdev/lspsaga.nvim/issues/1502
      -- maps.show_diagnostic = cmd("show_line_diagnostics")

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

        if lsp.inlay_hint.is_enabled() then
          vim.notify("disabling inlay hints", nil, opts)
          lsp.inlay_hint.enable(false)
        else
          vim.notify("enabling inlay hints", nil, opts)
          lsp.inlay_hint.enable(true)
        end
      end
    end

    return maps
  end

  local Leader = km.Leader

  function attach_keymaps()
    configure()

    -- set up key bindings
    km.buf.nnoremap.gD           = { maps.declaration, "Go to declaration", KEYMAP_TAG }
    km.buf.nnoremap.gd           = { maps.type_definition, "Go to type definition", KEYMAP_TAG }
    km.buf.nnoremap.gi           = { maps.implementation, "Go to implementation", KEYMAP_TAG }

    km.buf.nnoremap.K            = { maps.hover, "Hover info", KEYMAP_TAG }

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


---@param lhs string
---@param rhs string
---@return integer
local function common_prefix_len(lhs, rhs)
  local n = 0
  for i = 1, #lhs do
    local a = byte(lhs, i)
    local b = byte(rhs, i)
    if a ~= b then
      break
    end

    if a == SLASH then
      n = n + 1
    end
  end
  return n
end


local function cmp_match_length(a, b)
  return a.matched > b.matched
end

-- sorts entries from vim.lsp.tagfunc to prioritize matches with the longest
-- common prefix with the source buffer filename
local function tagfunc(pattern, flags, ctx)
  ---@type string|nil
  local fname = ctx and ctx.buf_ffname

  local res = lsp.tagfunc(pattern, flags)

  if fname and res ~= vim.NIL and #res > 1 then
    local copy = {}
    for i = 1, #res do
      local item = res[i]
      copy[i] = item

      if item.filename then
        item.matched = common_prefix_len(fname, item.filename)
      else
        item.matched = 0
      end
    end

    sort(copy, cmp_match_length)

    return copy
  end

  return res
end


---@param _client_id number
---@param buf    number
function _M.on_attach(_client_id, buf)
  attach_keymaps()

  vim.diagnostic.config({
    virtual_text = false,
    float = {
      border = "rounded",
    },
  })

  _G.__my_lua_tag_func = tagfunc
  vim.bo[buf].tagfunc = "v:lua.__my_lua_tag_func"

  vim.bo[buf].omnifunc = "v:lua.vim.lsp.omnifunc"
end

local function no_more_attached_clients(buf, client_id)
  local clients = lsp.get_clients({ bufnr = buf })
  if not clients then
    return true

  elseif #clients == 0 then
    return true

  elseif #clients == 1 and clients[1].id == client_id then
    return true
  end

  return false
end

---@param client_id number
---@param buf    number
function _M.on_detach(client_id, buf)
  -- no more connected clients (or this was the last one)
  if no_more_attached_clients(buf, client_id) then
    vim.schedule(function()
      if api.nvim_buf_is_valid(buf) then
        vim.notify("[lsp] teardown for midterms")
        vim.bo[buf].tagfunc = nil
        vim.bo[buf].omnifunc = nil
        km.remove_by_tag(KEYMAP_TAG)
      end
    end)
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
  if const.headless then
    return
  end

  if not plugin.installed("nvim-lspconfig") then
    vim.notify("nvim-lspconfig is not installed, some things might not work",
               vim.log.levels.WARN)
  end

  require("lspconfig")

  if const.lsp_debug then
    LOG_LEVEL = const.lsp_log_level
    require("my.lsp.logger").init()
  end
  lsp.set_log_level(LOG_LEVEL)

  lsp.config("*", {
    capabilities = make_capabilities(),
    log_level = LOG_LEVEL,
  })

  for _, server in ipairs(SERVERS) do
    setup_server(server)
  end
end


return _M
