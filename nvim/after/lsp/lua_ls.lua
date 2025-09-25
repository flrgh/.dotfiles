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
---@field ignoreDir string[]
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
---
---@field doc? table
---@field window? table
---@field spell? table

local fs = require "my.utils.fs"
local luamod = require "my.utils.luamod"
local const = require "my.constants"
local plugin = require "my.utils.plugin"
local sw = require "my.utils.stopwatch"
local WS = require "my.workspace"
local event = require "my.event"
local proto = require("vim.lsp.protocol")
local clear = require("table.clear")
local storage = require("my.storage")

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


---@class my.lsp.config.Lua: vim.lsp.Config
local DEFAULT_CONFIG = {
  cmd = nil,
  root_dir = nil,
  settings = {
    ---@type my.lsp.LuaLS
    Lua = {
      completion = {
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
      },

      diagnostics = {
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
      },

      doc = {
        packageName = nil,
        privateName = nil,
        protectedName = nil,
      },

      format = {
        defaultConfig = nil,
        enable = false,
      },

      hint = {
        enable     = true,
        paramName  = "All",
        paramType  = true,
        setType    = true,
        arrayIndex = "Enable",
        await      = false,
        semicolon  = Disable,
      },

      hover = {
        enable        = true,
        enumsLimit    = 10,
        expandAlias   = true,
        previewFields = 20,
        viewNumber    = true,
        viewString    = true,
        viewStringMax = 1000,
      },

      IntelliSense = {
        -- https://github.com/sumneko/lua-language-server/issues/872
        traceLocalSet    = true,
        traceReturn      = true,
        traceBeSetted    = true,
        traceFieldInject = true,
      },

      runtime = {
        builtin           = "enable",
        fileEncoding      = "utf8",
        meta              = nil,
        nonstandardSymbol = nil,
        ---@type string[]
        path              = { "?.lua", "?/init.lua" },
        pathStrict        = true,
        plugin            = nil,
        pluginArgs        = nil,
        special = {
          ["my.utils.luamod.reload"] = "require",
          ["my.utils.luamod.if_exists"] = "require",
          ["busted.require"] = "require",
        },
        unicodeName       = false,
        version           = "LuaJIT",
      },

      semantic = {
        annotation = true,
        enable     = true,
        keyword    = true,
        variable   = true,
      },

      signatureHelp = {
        enable = false,
      },

      spell = {
        dict = nil,
      },

      type = {
        castNumberToInteger = true,
        weakUnionCheck      = true,
        weakNilCheck        = true,
      },

      window = {
        progressBar = false,
        statusBar   = false,
      },

      workspace = {
        checkThirdParty  = Disable,
        ---@type string[]
        ignoreDir        = {},
        ignoreSubmodules = true,
        ---@type string[]
        library          = {},
        maxPreload       = nil,
        preloadFileSize  = nil,
        useGitIgnore     = true,
        userThirdParty   = nil,
      },
    },
  },
}

do
  local diag = DEFAULT_CONFIG.settings.Lua.diagnostics

  -- explicitly disable diagnostics set to `None`
  -- idk if this has any real effect
  diag.disable = {}
  for name, val in pairs(diag.neededFileStatus) do
    if val == None then
      insert(diag.disable, name)
    end
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

---@param p string
---@param skip_realpath? boolean
---@return string
local function normalize(p, skip_realpath)
  if skip_realpath then
    return fs.normalize(p)
  else
    return fs.realpath(p)
  end
end

---@param paths string[]
---@param skip_realpath? boolean
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


---@type { [integer|string]: my.lua.state }
local STATES = {}

---@class my.lua.state
---
---@field id integer
---@field resolver my.lua.resolver
---@field config my.lsp.config.Lua
local State = {
  id = nil,
  resovler = nil,
  config = nil,
}

local state_mt = { __index = State }


---@param id integer|"default"
---@param config? my.lsp.config.Lua
---@return my.lua.state
function State.new(id, config)
  local self = setmetatable({
    id = id,
    client = nil,
    config = deepcopy(config),
    resolver = nil,
  }, state_mt)

  STATES[id] = self

  return self
end


---@return my.lua.state
function State.default()
  return State.new("default", DEFAULT_CONFIG)
end


---@param id integer
---@return my.lua.state
function State.get_or_create(id)
  assert(type(id) == "number")

  if STATES[id] then
    return STATES[id]
  end

  local config = STATES.default
    and STATES.default.config
    or DEFAULT_CONFIG

  return State.new(id, config)
end


---@param search string
---@param tree? my.lua.resolver.path
---@return boolean changed
function State:update_runtime_path(search, tree)
  local path = self.config.settings.Lua.runtime.path
  local npaths = #path

  for i = 1, npaths do
    if path[i] == search then
      return false
    end
  end

  path[npaths + 1] = search

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
function State:update_workspace_library(path, tree)
  local library = self.config.settings.Lua.workspace.library
  local nlibs = #library

  local ft, lt = fs.type(path)
  local is_file = ft == "file" or lt == "file"

  if is_file then
    for i = 1, nlibs do
      local lib = library[i]
      if lib == path or path:find(lib, nil, true) == 1 then
        return false
      end
    end

  else
    for i = 1, nlibs do
      if library[i] == path then
        return false
      end
    end
  end

  library[nlibs + 1] = path

  lsp.log.info({
    event = "insert Lua.workspace.library",
    path = path,
    meta = tree and tree.meta,
  })

  return true
end


---@param client? vim.lsp.Client
function State:update_client_settings(client)
  client = client or lsp.get_clients({ name = NAME })[1]
  if not client then
    return
  end

  local settings = self.config.settings
  if deep_equal(client.settings, settings) then
    return
  end

  client.settings = deepcopy(settings)

  do
    -- avoid triggering `workspace/didChangeWorkspaceFolders` by tricking
    -- lspconfig into thinking that the client already knows about all of
    -- our workspace directories

    client.workspace_folders = client.workspace_folders or {}
    local seen = {}
    for _, item in ipairs(client.workspace_folders) do
      seen[item.name] = true
    end

    local resolver = self.resolver
    if resolver then
      for _, tree in ipairs(resolver.paths) do
        if tree.dir ~= "" and not seen[tree.dir] then
          seen[tree.dir] = true
          insert(client.workspace_folders, {
            name = tree.dir,
            uri = vim.uri_from_fname(tree.dir),
          })
        end
      end
    end
  end

  vim.notify("Updating LuaLS settings...")
  local ok = client:notify(workspaceDidChangeConfiguration,
                           { settings = settings })

  if not ok then
    vim.notify("Failed updating LuaLS settings", vim.log.levels.WARN)
  end
end


---@param settings my.lsp.settings
function State:rebuild_library(settings)
  local libs = {}

  extend(libs, settings.libraries)
  extend(libs, settings.definitions)

  libs = dedupe(libs)
  local library = self.config.settings.Lua.workspace.library
  clear(library)
  for i = 1, #libs do
    library[i] = libs[i]
  end
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
function State:rebuild_path(settings)
  local path = self.config.settings.Lua.runtime.path
  clear(path)

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
  insert(path, "?.lua")
  insert(path, "?/init.lua")

  for _, lib in ipairs(settings.libraries or EMPTY) do
    lib = fs.normalize(lib)
    -- add $path
    add_lua_path(path, lib, seen)

    -- add $path/lua
    if not endswith(lib, '/lua') and fs.dir_exists(lib .. '/lua') then
      add_lua_path(path, lib .. '/lua', seen)
    end

    -- add $path/src
    if not endswith(lib, '/src') and fs.dir_exists(lib .. '/src') then
      add_lua_path(path, lib .. '/src', seen)
    end

    -- add $path/lib
    if not endswith(lib, '/lib') and fs.dir_exists(lib .. '/lib') then
      add_lua_path(path, lib .. '/lib', seen)
    end
  end

  for _, dir in ipairs(LUA_PATH_ENTRIES) do
    add_lua_path(path, dir, seen)
  end
end

---@param settings my.lsp.settings
function State:rebuild_ignore(settings)
  local ignoreDir = self.config.settings.Lua.workspace.ignoreDir
  clear(ignoreDir)

  local ignore = settings.ignore
  if not ignore then
    return
  end

  for i = 1, #ignore do
    ignoreDir[i] = ignore[i]
  end
end

---@param ws? my.lsp.settings
function State:init_resolver(ws)
  local resolver = luamod.resolver.new()
  self.resolver = resolver

  ws = ws or get_merged_settings()

  resolver:add_lua_package_path()
  resolver:add_env_lua_path()

  for _, dir in ipairs(ws.definitions or EMPTY) do
    resolver:add_dir(dir, { source = SRC_TYPE_DEFS })
  end

  local path = self.config.settings.Lua.runtime.path
  for _, p in ipairs(path) do
    resolver:add_path(p, { source = SRC_RUNTIME_PATH })
  end

  local libraries = ws.libraries

  for _, lib in ipairs(libraries) do
    resolver:add_dir(lib, { source = SRC_WS_LIBRARY })
  end

  if ws.root_dir then
    resolver:add_dir(ws.root_dir,
                     { source = SRC_WORKSPACE_ROOT })
  end

  if WS.meta.nvim then
    if fs.dir_exists(WS.dir .. "/lua") then
      resolver:add_dir(WS.dir .. "/lua",
                       { source = SRC_WS_LIBRARY })
    end

    for _, p in ipairs(plugin.list()) do
      if p.dir and p.dir ~= "" then
        resolver:add_dir(p.dir .. "/lua",
                         {
                           source = SRC_PLUGIN,
                           plugin = p.name,
                         })
      end
    end
  end
end

---@param found my.lua.resolver.module[]
---@param state my.lua.state
local function update_settings_from_requires(found, state)
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
      state:update_runtime_path(search, tree)
    end
  end

  ---@param mod my.lua.resolver.module
  local function add_libs(mod)
    local tree = mod.tree

    if tree.meta.source == SRC_PLUGIN
      or tree.meta.source == SRC_RUNTIME_PATH
    then
      local fullpath = tree.dir .. "/" .. mod.fname
      state:update_workspace_library(fullpath, tree)

    else
      state:update_workspace_library(tree.dir, tree)
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


---@param ws my.lsp.settings
function State:reconfigure(ws)
  if ws.luarc_settings then
    return
  end

  self:rebuild_library(ws)
  self:rebuild_path(ws)
  self:rebuild_ignore(ws)
  self.config.root_dir = ws.root_dir
end

do
  ---@param client vim.lsp.Client
  ---@param buf integer
  local function on_attach(client, buf)
    local attach_done = sw.new("lua-lsp.on-attach", 1000)
    local state = State.get_or_create(client.id)

    local ws = get_merged_settings()

    if ws.luarc_settings then
      attach_done()
      return
    end

    vim.defer_fn(function()
      state:reconfigure(ws)

      if not state.resolver then
        state:init_resolver(ws)
      end

      storage.buffer.lua_resolver = state.resolver

      state:update_client_settings(client)
      attach_done()
    end, 0)
  end

  ---@param client vim.lsp.Client
  ---@param buf integer
  local function on_detach(client, buf)
    storage.buffer.lua_resolver = nil
  end

  local helpers = require("my.lsp.helpers")
  helpers.on_attach(NAME, on_attach)
  helpers.on_detach(NAME, on_detach)
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

    local client = lsp.get_clients({ name = NAME })[1]
    local id = client and client.id
    if not id then
      return
    end
    local state = STATES[id]
    if not state or not state.resolver then
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
        local mod = state.resolver:find_module(modname)
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

    update_settings_from_requires(found, state)
    state:update_client_settings(client)
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

  event.on({
    event.BufNew,
    event.BufNewFile,
    event.BufAdd,
    event.BufRead,
    event.BufWinEnter,
    event.TextChanged,
    event.TextChangedI
  }):group("user-lua-buf-event")
    :pattern("*.lua")
    :desc("Lua buffer event handler")
    :callback(on_buf_event)
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

    local client = lsp.get_clients({ name = NAME })[1]
    if not client then
      return
    end
    local state = STATES[client.id]

    for _, path in ipairs(found) do
      changed = state:update_workspace_library(path) or changed
    end

    if changed then
      state:update_client_settings(client)
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

  event.on(event.DiagnosticChanged)
    :group("user-lua-diagnostic")
    :pattern("*")
    :callback(diagnostic_changed)
end


do
  if WS.meta.lua then
    local settings = get_merged_settings()
    local state = State.get_or_create(0)

    vim.defer_fn(function()
      state:init_resolver(settings)
    end, 0)

    state:reconfigure(settings)
  end
end


return DEFAULT_CONFIG
