if require("my.constants").bootstrap then
  return
end

local vim = vim
local lsp = vim.lsp
local api = vim.api

local NAME = "lua_ls"

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
---@field checkThirdParty? any
---@field ignoreSubmodules? boolean
---@field library string[]
---@field useGitIgnore? boolean
---@field userThirdParty? any

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

local fs = require "my.utils.fs"
local luamod = require "my.utils.luamod"
local const = require "my.constants"
local plugin = require "my.utils.plugin"
local sw = require "my.utils.stopwatch"
local WS = require "my.workspace"
local event = require "my.event"
local proto = require("vim.lsp.protocol")
local clear = require("table.clear")

local endswith = vim.endswith
local insert = table.insert
local deepcopy = vim.deepcopy
local deep_equal = vim.deep_equal
local workspaceDidChangeConfiguration = proto.Methods.workspace_didChangeConfiguration


local Disable = "Disable"
local Replace = "Replace"
local Fallback = "Fallback"
local Opened = "Opened!"
local None = "None!"


---@type my.lua.resolver
local Resolver

local Completion = {
  enable           = true,
  autoRequire      = false,
  callSnippet      = Disable,
  displayContext   = 0, -- disabled
  keywordSnippet   = Disable,
  postfix          = "@",
  requireSeparator = ".",
  showParams       = true,
  showWord         = Fallback,
  workspaceWord    = false,
}

local Diagnostics = {
  enable = false,
  disable = nil,

  globals = {
    'vim',

    -- openresty/kong globals
    'ngx',
    'kong',

    -- busted globals
    'after_each',
    'before_each',
    'describe',
    'expose',
    'finally',
    'insulate',
    'it',
    'lazy_setup',
    'lazy_teardown',
    'mock',
    'pending',
    'pending',
    'randomize',
    'setup',
    'spec',
    'spy',
    'strict_setup',
    'strict_teardown',
    'stub',
    'teardown',
    'test',

  },

  ignoredFiles = Disable,
  libraryFiles = Disable,
  workspaceDelay = 3000,
  workspaceRate = 100,
  workspaceEvent = "OnSave",

  unusedLocalExclude = {
    "self",
  },

  neededFileStatus = {
    -- group: ambiguity
    ["ambiguity-1"]        = Opened,
    ["count-down-loop"]    = None,
    ["different-requires"] = None,
    ["newline-call"]       = None,
    ["newfield-call"]      = None,

    -- group: await
    ["await-in-sync"] = None,
    ["not-yieldable"] = None,

    -- group: codestyle
    ["codestyle-check"]  = None,
    ["name-style-check"] = None,
    ["spell-check"]      = None,

    -- group: conventions
    ["global-element"] = Opened,

    -- group: duplicate
    ["duplicate-index"]        = Opened,
    ["duplicate-set-field"]    = Opened,

    -- group: global
    ["global-in-nil-env"]      = None,
    ["lowercase-global"]       = None,
    ["undefined-env-child"]    = None,
    ["undefined-global"]       = Opened,

    -- group: luadoc
    ["cast-type-mismatch"]       = Opened,
    ["circle-doc-class"]         = None,
    ["doc-field-no-class"]       = Opened,
    ["duplicate-doc-alias"]      = Opened,
    ["duplicate-doc-field"]      = Opened,
    ["duplicate-doc-param"]      = Opened,
    ["incomplete-signature-doc"] = Opened,
    ["missing-global-doc"]       = None,
    ["missing-local-export-doc"] = None,
    ["undefined-doc-class"]      = Opened,
    ["undefined-doc-name"]       = Opened,
    ["undefined-doc-param"]      = Opened,
    ["unknown-cast-variable"]    = Opened,
    ["unknown-diag-code"]        = Opened,
    ["unknown-operator"]         = Opened,

    -- group: redefined
    ["redefined-local"]        = Opened,

    -- group: strict
    ["close-non-object"]       = None,
    ["deprecated"]             = Opened,
    ["discard-returns"]        = None,

    -- group: strong
    ["no-unknown"] = None,

    -- group: type-check
    ["assign-type-mismatch"] = Opened,
    ["cast-local-type"]      = Opened,
    ["cast-type-mismatch"]   = Opened,
    ["inject-field"]         = Opened,
    ["need-check-nil"]       = Opened,
    ["param-type-mismatch"]  = Opened,
    ["return-type-mismatch"] = Opened,
    ["undefined-field"]      = Opened,

    -- group: unbalanced
    ["missing-fields"]         = Opened,
    ["missing-parameter"]      = Opened,
    ["missing-return"]         = Opened,
    ["missing-return-value"]   = Opened,
    ["redundant-parameter"]    = Opened,
    ["redundant-return-value"] = Opened,
    ["redundant-value"]        = Opened,
    ["unbalanced-assignments"] = Opened,

    -- group: unused
    ["code-after-break"] = Opened,
    ["empty-block"]      = None,
    ["redundant-return"] = None,
    ["trailing-space"]   = None,
    ["unreachable-code"] = Opened,
    ["unused-function"]  = Opened,
    ["unused-label"]     = Opened,
    ["unused-local"]     = Opened,
    ["unused-vararg"]    = Opened,
  }
}

do
  -- explicitly disable diagnostics set to `None`
  -- idk if this has any real effect
  Diagnostics.disable = {}
  for name, val in pairs(Diagnostics.neededFileStatus) do
    if val == None then
      insert(Diagnostics.disable, name)
    end
  end
end

local Doc = {
  packageName = nil,
  privateName = nil,
  protectedName = nil,
}

local Format = {
  defaultConfig = nil,
  enable = false,
}

local Hint = {
  enable     = true,
  paramName  = "All",
  paramType  = true,
  setType    = true,
  arrayIndex = "Enable",
  await      = false,
  semicolon  = Disable,
}

local Hover = {
  enable        = true,
  enumsLimit    = 10,
  expandAlias   = true,
  previewFields = 20,
  viewNumber    = true,
  viewString    = true,
  viewStringMax = 1000,
}

local IntelliSense = {
  -- https://github.com/sumneko/lua-language-server/issues/872
  traceLocalSet    = true,
  traceReturn      = true,
  traceBeSetted    = true,
  traceFieldInject = true,
}

---@type string[]
local Path = { "?.lua", "?/init.lua" }

local Runtime = {
  builtin           = "enable",
  fileEncoding      = "utf8",
  meta              = nil,
  nonstandardSymbol = nil,
  path              = Path,
  pathStrict        = true,
  plugin            = nil,
  pluginArgs        = nil,
  special = {
    ["my.utils.luamod.reload"] = "require",
    ["my.utils.luamod.if_exists"] = "require",
  },
  unicodeName       = false,
  version           = "LuaJIT",
}

---@type string[]
local Library = {}

---@type string[]
local IgnoreDir = {}

local Workspace = {
  checkThirdParty  = Disable,
  ignoreDir        = IgnoreDir,
  ignoreSubmodules = true,
  library          = Library,
  maxPreload       = nil,
  preloadFileSize  = nil,
  useGitIgnore     = true,
  userThirdParty   = nil,
}

local Semantic = {
  annotation = true,
  enable     = true,
  keyword    = true,
  variable   = true,
}

local SignatureHelp = {
  enable = false,
}

local Spell = {
  dict = nil,
}

local Type = {
  castNumberToInteger = true,
  weakUnionCheck      = true,
  weakNilCheck        = true,
}

local Window = {
  progressBar = false,
  statusBar   = false,
}

---@type my.lsp.LuaLS
local Lua = {}

---@type { Lua: my.lsp.LuaLS }
local Settings = {}

---@type nil|string|function
local RootDir

---@type nil|string[]
local Cmd

---@class my.lsp.config.Lua: vim.lsp.Config
local Config = {}


local function reassemble()
  Runtime.path = Path
  Lua.runtime  = Runtime

  Workspace.library = Library
  Workspace.ignoreDir = IgnoreDir
  Lua.workspace     = Workspace

  Lua.IntelliSense  = IntelliSense
  Lua.completion    = Completion
  Lua.diagnostics   = Diagnostics
  Lua.doc           = Doc
  Lua.format        = Format
  Lua.hint          = Hint
  Lua.hover         = Hover
  Lua.semantic      = Semantic
  Lua.signatureHelp = SignatureHelp
  Lua.spell         = Spell
  Lua.type          = Type
  Lua.window        = Window

  Settings.Lua = Lua

  Config.settings = Settings
  Config.root_dir = RootDir
  Config.cmd = Cmd
end


local EMPTY = {}

local SRC_TYPE_DEFS = "type-definitions"
local SRC_RUNTIME_PATH = "Lua.runtime.path"
local SRC_WS_LIBRARY = "Lua.workspace.library"
local SRC_PLUGIN = "plugin"
local SRC_LUA_PATH = "$LUA_PATH / package.path"
local SRC_WORKSPACE_ROOT = "LSP.root_dir"


---@type string[]
local LUA_PATH_ENTRIES = luamod.LUA_PATH_ENTRIES

local LUA_TYPE_ANNOTATIONS = const.git_user_root .. "/lua-type-annotations"

---@type my.lsp.settings
local SETTINGS_COMMON = {
  libraries = {
    const.git_user_root .. "/lua-utils/lib",
  },
  definitions = {
    LUA_TYPE_ANNOTATIONS .. "/Penlight",
    LUA_TYPE_ANNOTATIONS .. "/LuaFileSystem",
    LUA_TYPE_ANNOTATIONS .. "/luasocket",
  },
}

---@param search string
---@param tree? my.lua.resolver.path
---@return boolean changed
local function update_runtime_path(search, tree)
  local npaths = #Path

  for i = 1, npaths do
    if Path[i] == search then
      return false
    end
  end

  Path[npaths + 1] = search

  lsp.log.info({
    event = "insert Lua.runtime.path",
    path = search,
    meta = tree and tree.meta,
  })

  return true
end

---@param path string
---@param tree? my.lua.resolver.path
---@return boolean changed
local function update_workspace_library(path, tree)
  local nlibs = #Library

  local ft, lt = fs.type(path)
  local is_file = ft == "file" or lt == "file"

  if is_file then
    for i = 1, nlibs do
      local lib = Library[i]
      if lib == path or path:find(lib, nil, true) == 1 then
        return false
      end
    end

  else
    for i = 1, nlibs do
      if Library[i] == path then
        return false
      end
    end
  end

  Library[nlibs + 1] = path

  lsp.log.info({
    event = "insert Lua.workspace.library",
    path = path,
    meta = tree and tree.meta,
  })

  return true
end


---@param settings my.lsp.LuaLS
---@param client? vim.lsp.Client
local function update_client_settings(client)
  client = client or lsp.get_clients({ name = NAME })[1]
  if not client then
    return
  end

  reassemble()

  if deep_equal(client.settings, Settings) then
    return
  end

  client.settings = deepcopy(Settings)

  do
    -- avoid triggering `workspace/didChangeWorkspaceFolders` by tricking
    -- lspconfig into thinking that the client already knows about all of
    -- our workspace directories

    client.workspace_folders = client.workspace_folders or {}
    local seen = {}
    for _, item in ipairs(client.workspace_folders) do
      seen[item.name] = true
    end

    for _, tree in ipairs(Resolver.paths) do
      if tree.dir ~= "" and not seen[tree.dir] then
        seen[tree.dir] = true
        insert(client.workspace_folders, {
          name = tree.dir,
          uri = vim.uri_from_fname(tree.dir),
        })
      end
    end
  end

  vim.notify("Updating LuaLS settings...")
  local ok = client:notify(workspaceDidChangeConfiguration,
                           { settings = Settings })

  if not ok then
    vim.notify("Failed updating LuaLS settings", vim.log.levels.WARN)
  end
end

---@param t string[]
---@param extra string|string[]
local function extend(t, extra)
  if extra == nil then
    return
  end

  if type(extra) == "table" then
    for _, v in ipairs(extra) do
      insert(t, v)
    end
  else
    insert(t, extra)
  end
end

---@param name string
---@return string|nil
local function get_plugin_lua_dir(name)
  local p = plugin.get(name)
  if p and p.dir and p.dir ~= "" then
    local lua_dir = p.dir .. "/lua"
    if fs.dir_exists(lua_dir) then
      return lua_dir
    end
  end
end

---@param settings my.lsp.settings
---@return boolean loaded
local function load_luarc_settings(settings)
  if WS.meta.luarc then
    settings.luarc = true
    local fname = fs.join(WS.dir, ".luarc.json")
    settings.luarc_settings = fs.load_json_file(fname)
    return true
  end

  return false
end

---@class my.lsp.settings
---@field ignore?           string[]
---@field libraries?        string[]
---@field definitions?      string[]
---@field plugins?          string[]
---@field luarc_settings?   my.lsp.LuaLS
---@field override_all?     boolean
---@field luarocks?         boolean
---@field luarc?            boolean
---@field root_dir          function|string|nil
local DEFAULT_SETTINGS = {
  libraries = {},
  ignore = {},
  plugins = {},
  definitions = {},
  luarc = false,
  luarc_settings = nil,
  override_all = nil,
  luarocks = nil,
  root_dir = nil,
}

---@param p string
---@return string
local function normalize(p, skip_realpath)
  if skip_realpath then
    return fs.normalize(p)
  else
    return fs.realpath(p)
  end
end

---@param a table
---@param b table
---@return table|nil
local function imerge(a, b)
  if not b then return end
  local seen = {}

  for _, v in ipairs(a) do
    seen[v] = true
  end

  for _, v in ipairs(b) do
    if not seen[v] then
      seen[v] = true
      insert(a, v)
    end
  end

  return a
end

---@param paths string[]
---@return string[]
local function dedupe(paths, skip_realpath)
  local seen = {}
  local new = {}
  local i = 0
  for _, p in ipairs(paths) do
    p = normalize(p, skip_realpath)
    if not seen[p] then
      seen[p] = true
      i = i + 1
      new[i] = p
    end
  end
  return new
end

---@param current my.lsp.settings
---@param extra my.lsp.settings
local function merge_settings(current, extra)
  imerge(current.libraries, extra.libraries)
  imerge(current.definitions, extra.definitions)
  imerge(current.ignore, extra.ignore)
  imerge(current.plugins, extra.plugins)
  current.root_dir = extra.root_dir or current.root_dir
end

---@return my.lsp.settings
local function get_merged_settings()
  local settings = deepcopy(DEFAULT_SETTINGS)

  if load_luarc_settings(settings) then
    return settings
  end

  if WS.meta.lua then
    local ws_settings = {
      libraries = WS.meta["lua.libraries"],
      definitions = WS.meta["lua.definitions"],
      ignore = WS.meta["lua.ignore"],
      root_dir = WS.meta["lua.root_dir"]
    }

    merge_settings(settings, ws_settings)
  end

  if WS.meta.nvim then
    for _, name in ipairs(settings.plugins or EMPTY) do
      local lib = get_plugin_lua_dir(name)
      if lib then
        insert(settings.libraries, lib)
      end
    end

    -- lua files for neovim plugins typically live at <repo>/lua
    local lua_dir = WS.dir .. "/lua"
    if fs.dir_exists(lua_dir) then
      insert(settings.libraries, lua_dir)
    end
  end

  if WS.meta.luarocks then
    -- luarocks config deploy_lua_dir
    local res = vim.system({ "luarocks", "config", "deploy_lua_dir" },
                           { text = true }
                          ):wait()

    local stdout = res and res.stdout and #res.stdout > 0 and res.stdout
    if stdout then
      stdout = vim.trim(stdout)
      insert(settings.libraries, stdout)
    end
  end

  merge_settings(settings, SETTINGS_COMMON)

  return settings
end


---@param settings my.lsp.settings
local function rebuild_library(settings)
  local libs = {}

  extend(libs, settings.libraries)
  extend(libs, settings.definitions)

  libs = dedupe(libs)
  clear(Library)
  for i = 1, #libs do
    Library[i] = libs[i]
  end
end

---@param paths string[]
---@param dir string
---@param seen table<string, true>
local function add_lua_path(paths, dir, seen)
  if not dir or dir == "" then return end

  if not seen[dir] then
    seen[dir] = true
    insert(paths, dir .. "/?.lua")
    insert(paths, dir .. "/?/init.lua")
  end
end

---@param settings my.lsp.settings
local function rebuild_path(settings)
  clear(Path)

  local seen = {}

  -- something changed in lua-language-server 2.5.0 with regards to locating
  -- `require`-ed filenames from package.path. These no longer work:
  --
  -- * relative (`./`) references to the current working directory:
  --   * ./?.lua
  --   * ./?/init.lua
  -- * absolute references to the current working directory:
  --   * $PWD/?.lua
  --   * $PWD/?/init.lua
  --
  -- ...but `?.lua` and `?/init.lua` work, so let's use them instead
  insert(Path, "?.lua")
  insert(Path, "?/init.lua")

  for _, lib in ipairs(settings.libraries or EMPTY) do
    lib = fs.normalize(lib)
    -- add $path
    add_lua_path(Path, lib, seen)

    -- add $path/lua
    if not endswith(lib, '/lua') and fs.dir_exists(lib .. '/lua') then
      add_lua_path(Path, lib .. '/lua', seen)
    end

    -- add $path/src
    if not endswith(lib, '/src') and fs.dir_exists(lib .. '/src') then
      add_lua_path(Path, lib .. '/src', seen)
    end

    -- add $path/lib
    if not endswith(lib, '/lib') and fs.dir_exists(lib .. '/lib') then
      add_lua_path(Path, lib .. '/lib', seen)
    end
  end

  for _, dir in ipairs(LUA_PATH_ENTRIES) do
    add_lua_path(Path, dir, seen)
  end
end

---@param settings my.lsp.settings
local function rebuild_ignore(settings)
  clear(IgnoreDir)

  local ignore = settings.ignore
  if not ignore then
    return
  end

  for i = 1, #ignore do
    IgnoreDir[i] = ignore[i]
  end
end

---@param ws? my.lsp.settings
local function init_resolver(ws)
  Resolver = luamod.resolver()

  ws = ws or get_merged_settings()

  Resolver:add_lua_package_path()
  Resolver:add_env_lua_path()

  for _, dir in ipairs(ws.definitions or EMPTY) do
    Resolver:add_dir(dir, { source = SRC_TYPE_DEFS })
  end

  for _, p in ipairs(Path) do
    Resolver:add_path(p, { source = SRC_RUNTIME_PATH })
  end

  local libraries = ws.libraries

  for _, lib in ipairs(libraries) do
    Resolver:add_dir(lib, { source = SRC_WS_LIBRARY })
  end

  if ws.root_dir then
    Resolver:add_dir(ws.root_dir,
                     { source = SRC_WORKSPACE_ROOT })
  end

  if WS.meta.nvim then
    if fs.dir_exists(WS.dir .. "/lua") then
      Resolver:add_dir(WS.dir .. "/lua",
                       { source = SRC_WS_LIBRARY })
    end

    for _, p in ipairs(plugin.list()) do
      if p.dir and p.dir ~= "" then
        Resolver:add_dir(p.dir .. "/lua",
                         {
                           source = SRC_PLUGIN,
                           plugin = p.name,
                         })
      end
    end
  end
end

---@param found my.lua.resolver.module[]
local function update_settings_from_requires(found)
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
      update_runtime_path(search, tree)
    end
  end

  ---@param mod my.lua.resolver.module
  local function add_libs(mod)
    local tree = mod.tree

    if tree.meta.source == SRC_PLUGIN
      or tree.meta.source == SRC_RUNTIME_PATH
    then
      local fullpath = tree.dir .. "/" .. mod.fname
      update_workspace_library(fullpath, tree)

    else
      update_workspace_library(tree.dir, tree)
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


local function reconfigure(ws)
  if ws.luarc_settings then
    return
  end

  rebuild_library(ws)
  rebuild_path(ws)
  rebuild_ignore(ws)
  RootDir = ws.root_dir
end

do
  ---@param client vim.lsp.Client
  ---@param buf integer
  local function on_attach(client, buf)
    local attach_done = sw.new("lua-lsp.on-attach", 1000)

    local ws = get_merged_settings()

    if ws.luarc_settings then
      attach_done()
      return
    end

    vim.defer_fn(function()
      reconfigure(ws)

      if not Resolver then
        init_resolver(ws)
      end

      update_client_settings(client)
      attach_done()
    end, 0)
  end

  require("my.lsp.helpers").on_attach(NAME, on_attach)
  require("my.lsp.helpers").on_detach(NAME, function()
    Resolver = nil
  end)
end


do
  ---@type { buf:integer, event:string, file:string }[]
  local Events = {}

  ---@type table<integer, true>
  local Busy = {}

  local get_module_requires = luamod.get_module_requires

  local scheduled = false

  local skip = {
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

  local function buf_update_handler()
    scheduled = false

    if not Resolver then
      return
    end

    local modnames = {}
    local seen = {}

    local n = #Events

    while n > 0 do
      local e = Events[n]
      Events[n] = nil
      n = n - 1

      local buf = e.buf
      for _, mod in ipairs(get_module_requires(buf) or EMPTY) do
        if not seen[mod] then
          seen[mod] = true
          insert(modnames, mod)
        end
      end

      Busy[buf] = nil
    end

    ---@type my.lua.resolver.module[]
    local found = {}
    local missing = {}

    for _, modname in ipairs(modnames) do
      if not skip[modname] then
        local mod = Resolver:find_module(modname)
        if mod then
          insert(found, mod)

        else
          insert(missing, modname)
        end
      end
    end

    if #found == 0 then
      return
    end

    update_settings_from_requires(found)
    update_client_settings()
  end

  local next_run = 0

  local function schedule_handler()
    if scheduled then
      return
    end

    scheduled = true

    local now = vim.uv.now()
    local delay = math.max(1, next_run - now)
    next_run = now + 1000

    vim.defer_fn(buf_update_handler, delay)
  end

  ---@param e { buf:integer, event:string, file:string }
  local function on_buf_event(e)
    local buf = e.buf

    if not buf
      or not Resolver
      or Busy[buf]
      or not WS.meta.lua
      or not api.nvim_buf_is_loaded(buf)
      or not vim.bo[buf].buflisted
      or vim.bo[buf].buftype == "scratch"
      or vim.bo[buf].bufhidden == "hide"
    then
      return
    end

    Busy[buf] = true
    insert(Events, e)
    schedule_handler()
  end

  local group = api.nvim_create_augroup("user-lua-buf-event", { clear = true })
  api.nvim_create_autocmd({
      event.BufNew,
      event.BufNewFile,
      event.BufAdd,
      event.BufRead,
      event.BufWinEnter,
      event.TextChanged,
      event.TextChangedI
    }, {
      group    = group,
      pattern  = "*.lua",
      desc     = "Lua buffer event handler",
      callback = on_buf_event,
    }
  )
end

do
  local _find_type_defs = luamod.find_type_defs

  ---@param names string[]
  local function find_type_defs(names)
    if not WS.meta.lua then
      return
    end

    local extra
    if WS.meta.nvim then
      extra = { const.nvim.plugins }
    end

    local found = _find_type_defs(names, extra)
    local changed = false
    local settings = Settings.Lua

    for _, path in ipairs(found) do
      changed = update_workspace_library(settings, path) or changed
    end

    if changed then
      update_client_settings()
    end
  end

  ---@param e _vim.autocmd.event
  local function diagnostic_changed(e)
    if not e.file then
      return

    elseif not fs.is_child(WS.dir, e.file) then
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
      local names = {}
      local seen = {}

      vim.schedule(function()
        for _, item in ipairs(items) do
          local name = api.nvim_buf_get_text(item.bufnr,
                                             item.lnum,
                                             item.col,
                                             item.end_lnum,
                                             item.end_col,
                                             {})

          name = name and name[1]
          if name and not seen[name] then
            seen[name] = true
            insert(names, name)
          end
        end

        if #names > 0 then
          find_type_defs(names)
        end
      end)
    end
  end

  local group = api.nvim_create_augroup("user-lua-diagnostic", { clear = true })
  api.nvim_create_autocmd(event.DiagnosticChanged, {
    group = group,
    pattern = "*",
    callback = diagnostic_changed,
  })
end


do
  if WS.meta.lua then
    local settings = get_merged_settings()
    vim.defer_fn(function()
      init_resolver(settings)
    end, 0)

    reconfigure(settings)
    reassemble()
  end
end


return Config
