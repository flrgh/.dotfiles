local _M = {}

_M.const = require("my.lsp.lua_ls.constants")
_M.defaults = require("my.lsp.lua_ls.defaults")
local hooks = require("my.lsp.lua_ls.hooks")
local Config = require("my.lsp.lua_ls.config")
local state = require("my.state")
local Set = require("my.std.set")
local path = require("my.std.path")

_M.config = Config
_M.hooks = hooks

local vim = vim
local lsp = vim.lsp
local api = vim.api
local defer_fn = vim.defer_fn
local uv_now = vim.uv.now
local math_max = math.max

local UPDATES = {}

---@param fn fun(conf: my.lua_ls.Config)
function _M.update(fn)
  table.insert(UPDATES, fn)
end

---@param conf my.lua_ls.Config
local function handle_updates(conf)
  for i = 1, #UPDATES do
    UPDATES[i](conf)
    UPDATES[i] = nil
  end
end


---@class my.lsp.LuaLS.runtime
---@field version?           string
---@field builtin?           string
---@field fileEncoding?      string
---@field nonstandardSymbol? string[]
---@field pathStrict?        boolean
---@field path?              string[]
---@field plugin?            any
---@field pluginArgs?        any
---@field special?           table<string, string>

---@class my.lsp.LuaLS.workspace
---
---@field checkThirdParty? string
---@field ignoreSubmodules? boolean
---@field ignoreDir string[]
---@field library string[]
---@field useGitIgnore? boolean
---@field userThirdParty? string[]

---@class my.lsp.LuaLS
---
---@field runtime my.lsp.LuaLS.runtime
---@field completion? table
---@field signatureHelp? table
---@field hover? table
---@field hint? table
---@field IntelliSense? table
---@field format? table
---@field diagnostics? table
---@field workspace my.lsp.LuaLS.workspace
---@field semantic? table
---@field type? table
---
---@field doc? table
---@field window? table
---@field spell? table

local fs = require "my.std.fs"
local luamod = require "my.std.luamod"
local sw = require "my.std.stopwatch"
local WS = require("my.env").workspace
local event = require "my.event"
local helpers = require("my.lsp.helpers")

local insert = table.insert
local deepcopy = vim.deepcopy

local EMPTY = {}

local NAME = _M.const.NAME

local SRC_TYPE_DEFS = "type-definitions"
local SRC_RUNTIME_PATH = "Lua.runtime.path"
local SRC_PLUGIN = "plugin"


local SKIPPED = {
  ["table.new"] = true,
  ["table.clone"] = true,
  ["table.nkeys"] = true,
  ["table.isarray"] = true,
  ["table.isempty"] = true,
  ["table.clear"] = true,
  ["string.buffer"] = true,
  ["cjson"] = true,
  ["cjson.safe"] = true,
  ["math"] = true,
  ["bit"] = true,
  ["ffi"] = true,
  ["require"] = true,
}



---@param found my.lua.resolver.module[]
---@param config my.lua_ls.Config
local function update_settings_from_requires(found, config)
  local skipped = {}

  ---@param tree my.lua.resolver.path
  ---@return boolean
  local function skip(tree)
    if tree.dir == "" then
      skipped[tree.dir] = "empty"
      return true
    end

    if tree.dir == WS.dir
      or tree.dir:find(WS.dir, nil, true) == 1
    then
      skipped[tree.dir] = "workspace"
      return true
    end

    if tree.meta.source == SRC_TYPE_DEFS then
      skipped[tree.dir] = "typedefs"
      return true
    end

    return false
  end

  ---@param mod my.lua.resolver.module
  local function add_paths(mod)
    local tree = mod.tree
    if tree.meta.source == SRC_TYPE_DEFS then
      return
    end

    for _, suf in ipairs(tree.suffixes) do
      local search = tree.dir .. "/?" .. suf
      config:add_runtime_path(search, tree)
    end
  end

  ---@param mod my.lua.resolver.module
  local function add_libs(mod)
    local tree = mod.tree

    if tree.meta.source == SRC_PLUGIN
      or tree.meta.source == SRC_RUNTIME_PATH
    then
      local fullpath = tree.dir .. "/" .. mod.fname
      config:add_workspace_library(fullpath, tree)

    else
      config:add_workspace_library(tree.dir, tree)
    end
  end

  for _, data in pairs(found) do
    local tree = data.tree

    if not skip(tree) then
      add_paths(data)
      add_libs(data)
    end
  end

end


do
  ---@type { buf: _vim.buffer.id, event: string, file: string }[]
  local Events = {}

  ---@type table<integer, true>
  local Busy = {}

  local get_module_requires = luamod.get_module_requires
  local clear = require("table.clear")

  local scheduled = false

  local function buf_update_handler()
    scheduled = false

    local events = Events
    Events = {}
    clear(Busy)

    if #events == 0 then
      return
    end

    local client = lsp.get_clients({ name = NAME })[1]
    local id = client and client.id
    if not id then
      return
    end

    local config = Config.get(id)
    if not config or not config.resolver then
      return
    end

    local modnames = Set.new()

    local seen = {}
    for i = 1, #events do
      local e = events[i]

      local buf = e.buf
      if seen[buf] then
        goto continue
      end
      seen[buf] = true

      local data = state.buffer[buf]
      if not data:is_loaded() or not data.lua_lsp then
        goto continue
      end

      for _, mod in ipairs(get_module_requires(buf) or EMPTY) do
        if not SKIPPED[mod] then
          modnames:add(mod)
        end
      end

      ::continue::
    end

    ---@type my.lua.resolver.module[]
    local found = {}
    local missing = {}

    local any_changed = false
    for _, modname in ipairs(modnames.items) do
      if hooks.on_lua_module(modname, config) then
        any_changed = true
      end

      local mod = config.resolver:find_module(modname)
      if mod then
        any_changed = true
        insert(found, mod)

      else
        insert(missing, modname)
      end
    end

    if any_changed then
      if #found ~= 0 then
        update_settings_from_requires(found, config)
      end
      config:update_client_settings(client)
    end
  end

  local next_run = 0

  ---@param e my.event.payload
  function _M.on_buf_event(e)
    local buf = e.buf
    if not buf then
      return
    end

    local buf_storage = state.buffer[buf]
    if not buf_storage:is_loaded() then
      return
    end

    if Busy[buf]
      or not buf_storage.lua_lsp
      or not vim.bo[buf].buflisted
      or vim.bo[buf].buftype == "scratch"
      or vim.bo[buf].bufhidden == "hide"
    then
      return
    end

    Busy[buf] = true
    insert(Events, e)
    if not scheduled then
      scheduled = true

      local now = uv_now()
      local delay = math_max(1, next_run - now)
      next_run = now + 1000

      defer_fn(buf_update_handler, delay)
    end
  end
end


---@param e my.event.payload
function _M.on_diagnostic_changed(e)
  if not e.file then
    return

  elseif not fs.is_child(WS.dir, e.file) then
    return
  end

  local config = state.buffer[e.buf].lua_lsp
  if not config then
    return
  end

  local client = lsp.get_clients({ name = NAME })[1]
  if not client then
    return
  end

  local diagnostics = e.data.diagnostics
  local items = {}
  for _, elem in ipairs(diagnostics) do
    if elem.code == "undefined-doc-name"
      and elem.source
      and elem.source:find("Lua")
    then
      insert(items, elem)
    end
  end

  if #items > 0 then
    local names = Set.new()

    vim.schedule(function()
      for _, item in ipairs(items) do
        local name = api.nvim_buf_get_text(item.bufnr,
                                           item.lnum,
                                           item.col,
                                           item.end_lnum,
                                           item.end_col,
                                           {})

        name = name and name[1]
        if name and name ~= "" then
          names:add(name)
        end
      end

      if names.len > 0 then
        hooks.on_missing_types(names.items, config)
        config:update_client_settings(client)
      end
    end)
  end
end


---@param client vim.lsp.Client
---@param buf integer
function _M.on_attach(client, buf)
  local attach_done = sw.new("lua-lsp.on-attach", 1000)

  event.on(event.DiagnosticChanged)
    :group("user-lua-diagnostic", true)
    :buffer(buf)
    :callback(_M.on_diagnostic_changed)

  event.on({
      event.BufNewFile,
      event.BufReadPost,
      event.TextChanged,
      event.TextChangedI,
    })
    :group("user-lua-buf-event", true)
    :desc("Lua buffer event handler")
    :buffer(buf)
    :callback(_M.on_buf_event)

  local config = Config.get(client.id)
  if not config then
    config = Config.get_or_create(client.id)
    hooks.on_workspace(WS, config)
  end

  for _, mod in ipairs(luamod.find_all_requires()) do
    hooks.on_lua_module(mod, config)
  end

  state.buffer[buf].lua_resolver = config.resolver

  handle_updates(config)
  config:update_client_settings(client)

  state.buffer[buf].lua_lsp = config

  attach_done()
end


---@param client vim.lsp.Client
---@param buf _vim.buffer.id
function _M.on_detach(client, buf)
  state.buffer[buf].lua_resolver = nil
  state.buffer[buf].lua_lsp = nil
end


local init = false

function _M.init()
  local config = Config.get_or_create(0)

  if not init then
    init = true
    helpers.on_attach(NAME, _M.on_attach)
    helpers.on_detach(NAME, _M.on_detach)

    hooks.on_workspace(WS, config)
    handle_updates(config)
  end

  return config.config
end


---@param buf? integer
---@return vim.lsp.Client?
function _M.get_client(buf)
  if not buf or buf == 0 then
    buf = api.nvim_get_current_buf()
  end

  local clients = lsp.get_clients({ buf = buf, name = _M.const.NAME })
  return clients and clients[1]
end

---@param buf? integer
---@return my.lua_ls.Config?
function _M.get_config(buf)
  local client = _M.get_client(buf)
  return client and Config.get(client.id)
end


return _M
