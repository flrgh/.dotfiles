if require("my.config.globals").bootstrap then
  return
end

local _M = {}

local vim = vim

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
local globals = require "my.config.globals"
local plugin = require "my.utils.plugin"
local sw = require "my.utils.stopwatch"
local WS = require "my.workspace"

local resolver = luamod.resolver()

_M.resolver = resolver

---@type { Lua: my.lsp.LuaLS }
_M.settings = nil

local client_attached = {}

local endswith = vim.endswith
local insert = table.insert
local deepcopy = vim.deepcopy
local tbl_deep_extend = vim.tbl_deep_extend
local deep_equal = vim.deep_equal

local EMPTY = {}

local SRC_TYPE_DEFS = "type-definitions"
local SRC_RUNTIME_PATH = "Lua.runtime.path"
local SRC_WS_LIBRARY = "Lua.workspace.library"
local SRC_PLUGIN = "plugin"
local SRC_LUA_PATH = "$LUA_PATH / package.path"


---@type string[]
local LUA_PATH_ENTRIES = {}
do
  local lua_path = os.getenv("LUA_PATH")
                or package.path
                or ""

  local seen = {}

  ---@diagnostic disable-next-line
  lua_path:gsub("[^;]+", function(path)
    local dir = path:gsub("%?%.lua$", "")
                    :gsub("%?/init%.lua$", "")
                    :gsub("%?%.ljbc$", "")
                    :gsub("%?/init.ljbc", "")

    dir = fs.normalize(dir)

    if path ~= ""
       and path ~= "/"
       and dir ~= globals.workspace
       and not seen[dir]
    then
      seen[dir] = dir
      insert(LUA_PATH_ENTRIES, dir)
    end
  end)
end

--- annotations from https://github.com/LuaCATS
local LUA_CATS = globals.git_root .. "/LuaCATS"

local LUA_TYPE_ANNOTATIONS = globals.git_user_root .. "/lua-type-annotations"

---@type my.lsp.settings
local SETTINGS_COMMON = {
  libraries = {
    globals.git_user_root .. "/lua-utils/lib",
  },
  definitions = {
    LUA_TYPE_ANNOTATIONS .. "/Penlight",
    LUA_TYPE_ANNOTATIONS .. "/LuaFileSystem",
    LUA_TYPE_ANNOTATIONS .. "/luasocket",
  },
}

---@type my.lsp.settings
local SETTINGS_RESTY = {
  definitions = {
    LUA_CATS .. "/openresty/library",
    globals.git_user_root .. "/resty-community-typedefs/library",
  },
}

local SETTINGS_DOTFILES = {
  libraries = {
    globals.dotfiles.config_nvim_lua,
  },
  plugins = {
    "lazy.nvim",
    "nvim-cmp",
    "nvim-lspconfig",
  },
}

---@type my.lsp.settings
local SETTINGS_NVIM = {
  libraries = {
    globals.nvim.runtime_lua,
  },
  ignore = {
    "lspconfig/server_configurations"
  },
}

---@type my.lsp.settings
local SETTINGS_KONG = {
  definitions = {
    LUA_TYPE_ANNOTATIONS .. "/kong",
  },
  ignore = {
    -- kong-build-tools
    ".kbt",

    -- busted test files
    "*_spec.lua",

    -- kong migration files
    "migrations/[0-9]*.lua",
    "migrations/**/[0-9]*.lua",

    -- local openresty build dir
    ".resty",

    --"spec/helpers.lua",
  },
}

---@param settings my.lsp.LuaLS
---@param search string
---@param tree? my.lua.resolver.path
---@return boolean changed
local function update_runtime_path(settings, search, tree)
  local paths = settings.runtime.path
  local npaths = #paths

  for i = 1, npaths do
    if paths[i] == search then
      return false
    end
  end

  paths[npaths + 1] = search

  vim.lsp.log.debug({
    event = "insert Lua.runtime.path",
    path = search,
    meta = tree and tree.meta,
  })

  return true
end

---@param settings my.lsp.LuaLS
---@param path string
---@param tree? my.lua.resolver.path
---@return boolean changed
local function update_workspace_library(settings, path, tree)
  settings.workspace.library = settings.workspace.library or {}
  local libs = settings.workspace.library
  local nlibs = #libs

  local ft, lt = fs.type(path)
  local is_file = ft == "file" or lt == "file"

  if is_file then
    for i = 1, nlibs do
      local lib = libs[i]
      if lib == path or path:find(lib, nil, true) == 1 then
        return false
      end
    end

  else
    for i = 1, nlibs do
      if libs[i] == path then
        return false
      end
    end
  end

  libs[nlibs + 1] = path

  vim.lsp.log.debug({
    event = "insert Lua.workspace.library",
    path = path,
    meta = tree and tree.meta,
  })

  return true
end

---@param settings my.lsp.LuaLS
---@param client? vim.lsp.Client
local function update_settings(settings, client)
  client = client or vim.lsp.get_clients({ name = "lua_ls" })[1]

  if not client then
    return
  end

  do
    -- avoid triggering `workspace/didChangeWorkspaceFolders` by tricking
    -- lspconfig into thinking that the client already knows about all of
    -- our workspace directories

    client.workspace_folders = client.workspace_folders or {}
    local wfs = {}
    for _, item in ipairs(client.workspace_folders) do
      wfs[item.name] = true
    end

    for _, tree in ipairs(resolver.paths) do
      if tree.dir ~= "" and not wfs[tree.dir] then
        wfs[tree.dir] = true
        insert(client.workspace_folders, {
          name = tree.dir,
          uri = vim.uri_from_fname(tree.dir),
        })
      end
    end
  end

  vim.notify("Updating LuaLS settings...")
  _M.settings.Lua = settings
  client.settings = _M.settings
  client.notify("workspace/didChangeConfiguration", _M.settings)
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
  if not p then return end
  local lua_dir = p.dir .. "/lua"
  if fs.dir_exists(lua_dir) then
    return lua_dir
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
local DEFAULT_SETTINGS = {
  libraries = {},
  ignore = {},
  plugins = {},
  definitions = {},
  luarc = false,
  luarc_settings = nil,
  override_all = nil,
  luarocks = nil,
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
end

---@return my.lsp.settings
local function get_merged_settings()
  local settings = deepcopy(DEFAULT_SETTINGS)

  if load_luarc_settings(settings) then
    return settings
  end

  merge_settings(settings, SETTINGS_COMMON)

  if WS.meta.dotfiles then
    merge_settings(settings, SETTINGS_DOTFILES)
  end

  if WS.meta.nvim then
    merge_settings(settings, SETTINGS_NVIM)

    if luamod.exists("neodev.config") then
      local nconf = require "neodev.config"
      insert(settings.definitions, nconf.root() .. "/types/stable")
    else
      vim.notify("module `neodev.config` is missing")
    end

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

  if WS.meta.resty then
    merge_settings(settings, SETTINGS_RESTY)
  end

  if WS.meta.kong then
    merge_settings(settings, SETTINGS_KONG)
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

  return settings
end


---@param settings my.lsp.settings
---@return string[]
local function workspace_libraries(settings)
  local libs = {}

  extend(libs, settings.libraries)
  extend(libs, settings.definitions)

  return dedupe(libs)
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
---@return string[]
local function runtime_paths(settings)
  local paths = {}
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
  insert(paths, "?.lua")
  insert(paths, "?/init.lua")

  for _, lib in ipairs(settings.libraries or EMPTY) do
    lib = fs.normalize(lib)
    -- add $path
    add_lua_path(paths, lib, seen)

    -- add $path/lua
    if not endswith(lib, '/lua') and fs.dir_exists(lib .. '/lua') then
      add_lua_path(paths, lib .. '/lua', seen)
    end

    -- add $path/src
    if not endswith(lib, '/src') and fs.dir_exists(lib .. '/src') then
      add_lua_path(paths, lib .. '/src', seen)
    end

    -- add $path/lib
    if not endswith(lib, '/lib') and fs.dir_exists(lib .. '/lib') then
      add_lua_path(paths, lib .. '/lib', seen)
    end
  end

  for _, dir in ipairs(LUA_PATH_ENTRIES) do
    add_lua_path(paths, dir, seen)
  end

  return paths
end

local Disable = "Disable"
local Replace = "Replace"
local Fallback = "Fallback"
local Opened = "Opened!"
local None = "None!"

---@param ws? my.lsp.settings
local function update_resolver(ws)
  local meta

  ws = ws or get_merged_settings()

  meta = { source = SRC_TYPE_DEFS }
  for _, dir in ipairs(ws.definitions or EMPTY) do
    resolver:add_dir(dir, meta)
  end

  local paths = _M.settings
            and _M.settings.Lua
            and _M.settings.Lua.runtime
            and _M.settings.Lua.runtime.path
             or { "?.lua", "?/init.lua" }

  meta = { source = SRC_RUNTIME_PATH }
  for _, p in ipairs(paths) do
    resolver:add_path(p, meta)
  end

  local libraries = ws.libraries

  meta = { source = SRC_WS_LIBRARY }
  for _, lib in ipairs(libraries) do
  --for _, lib in ipairs(libraries) do
    resolver:add_dir(lib, meta)
  end

  if WS.meta.nvim then
    if fs.dir_exists(WS.dir .. "/lua") then
      resolver:add_dir(WS.dir .. "/lua", {
        source = SRC_WS_LIBRARY,
      })
    end

    for _, p in ipairs(plugin.list()) do
      resolver:add_dir(p.dir .. "/lua", {
        source = SRC_PLUGIN,
        plugin = p.name,
      })
    end
  end

  meta = { source = SRC_LUA_PATH }
  for _, dir in ipairs(LUA_PATH_ENTRIES) do
    resolver:add_dir(dir, meta)
  end
end

---@param settings my.lsp.LuaLS
---@param found my.lua.resolver.module[]
local function update_settings_from_requires(settings, found)
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
      update_runtime_path(settings, search, tree)
    end
  end

  ---@param mod my.lua.resolver.module
  local function add_libs(mod)
    local tree = mod.tree

    if tree.meta.source == SRC_PLUGIN
      or tree.meta.source == SRC_RUNTIME_PATH
    then
      local fullpath = tree.dir .. "/" .. mod.fname
      update_workspace_library(settings, fullpath, tree)

    else
      update_workspace_library(settings, tree.dir, tree)
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

local init_autocmd
do
  local event = require "my.event"
  function init_autocmd()
    local group = vim.api.nvim_create_augroup("user-lua", { clear = true })
    vim.api.nvim_create_autocmd({
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
        callback = _M.on_buf_event,
      }
    )
  end
end

---@return lspconfig.Config
function _M.init()
  local settings = get_merged_settings()

  if WS.meta.lua then
    init_autocmd()
    vim.defer_fn(function()
      update_resolver(settings)
    end, 0)
  end

  ---@type lspconfig.Config
  local conf = {
    cmd = { 'lua-language-server' },
    settings = {
      Lua = nil,
    },
  }

  if settings.luarc_settings then
    conf.settings.Lua = settings.luarc_settings

  else
    ---@type my.lsp.LuaLS
    conf.settings.Lua = {
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
        path              = runtime_paths(settings),
        pathStrict        = true,
        plugin            = nil,
        pluginArgs        = nil,
        special = {
          ["my.utils.luamod.reload"] = "require",
          ["my.utils.luamod.if_exists"] = "require",
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
        ignoreDir        = nil,
        ignoreSubmodules = true,
        library          = nil,
        maxPreload       = nil,
        preloadFileSize  = nil,
        useGitIgnore     = true,
        userThirdParty   = nil,
      },
    }

    -- explicitly disable diagnostics set to `None`
    -- idk if this has any real effect
    conf.settings.Lua.diagnostics.disable = {}
    for name, val in pairs(conf.settings.Lua.diagnostics.neededFileStatus) do
      if val == None then
        insert(conf.settings.Lua.diagnostics.disable, name)
      end
    end
  end

  _M.settings = conf.settings

  return conf
end

---@param client vim.lsp.Client
---@param buf integer
function _M.on_attach(client, buf)
  if client_attached[client.id] then
    return
  end

  local attach_done = sw.new("lua-lsp.on-attach", 1000)

  client_attached[client.id] = true

  local ws = get_merged_settings()

  if ws.luarc_settings then
    attach_done()
    return
  end

  vim.defer_fn(function()
    local settings = {
      Lua = nil,
    }

    local library = workspace_libraries(ws)

    settings.Lua = {
      runtime = {
        path = runtime_paths(ws),
      },

      workspace = {
        ignoreDir = ws.ignore,
        library = library,
      }
    }

    local defaults = (ws.override_all and {}) or client.settings
    local new = tbl_deep_extend("force", defaults, settings)

    _M.settings = new

    if not deep_equal(client.settings, new) then
      update_settings(new.Lua, client)
    end

    attach_done()
  end,
    0
  )
end

---@param names string[]
function _M.find_type_defs(names)
  if not WS.meta.lua then
    return
  end

  local namepat = "(" .. table.concat(names, "|") .. ")"

  local cmd = {
    "rg",
    "--one-file-system",
    "--files-with-matches",
    "-g", "*.lua",
    "-e", "@alias +" .. namepat,
    "-e", "@enum +" .. namepat,
    "-e", "@class +" .. namepat,
  }

  if WS.meta.nvim then
    insert(cmd, globals.nvim.plugins)
  end

  for _, lib in ipairs(LUA_PATH_ENTRIES) do
    insert(cmd, lib)
  end

  vim.system(cmd, { text = true }, function(out)
    local results = {}
    local _ = out.stdout:gsub("[^\r\n]+", function(line)
      insert(results, line)
    end)

    local stderr = out.stderr
    if stderr == "" then stderr = nil end

    local changed = false

    local settings = _M.settings.Lua
    for _, path in ipairs(results) do
      changed = update_workspace_library(settings, path) or changed
    end

    if changed then
      update_settings(settings)
    end
  end)
end

_M.busy = {}

---@type { buf:integer, event:string, file:string }[]
local events = {}

local get_module_requires
do
  ---@type vim.treesitter.Query
  local query
  local get_parser = vim.treesitter.get_parser
  local parse_query = vim.treesitter.query.parse
  local get_node_text = vim.treesitter.get_node_text

  local query_text = [[
  (function_call
      name: (identifier) @func (#eq? @func "require")
      arguments: (arguments
        (string
          content: (string_content) @mod
      )
    )
  )
  ]]

  local query_opts = { all = true }


  ---@param buf integer
  ---@return string[]?
  function get_module_requires(buf)
    local lang = get_parser(buf, "lua")

    local syn = lang:parse()
    local root = syn[1]:root()

    query = query or assert(parse_query("lua", query_text))

    local result = {}
    local ok, iter = pcall(query.iter_matches, query, root, 0, 0, -1, query_opts)
    if not ok then
       vim.notify(vim.inspect({
            message = "error getting text from buffer",
            buf     = buf,
            file    = vim.api.nvim_buf_get_name(buf),
            error   = iter,
          }), vim.log.levels.WARN)
      return result
    end


    local pattern, match, metadata
    while true do
      ok, pattern, match, metadata = pcall(iter, pattern, match, metadata)

      if not ok then
         vim.notify(vim.inspect({
              message = "error getting text from buffer",
              buf     = buf,
              file    = vim.api.nvim_buf_get_name(buf),
              error   = pattern,
            }), vim.log.levels.WARN)
        return result
      end

      if not pattern or not match then break end

      local res = {}
      assert(#match == 2)

      for id, nodes in pairs(match) do
        local name = query.captures[id]

        assert(#nodes == 1)
        local ok, text = pcall(get_node_text, nodes[1], buf)
        if ok then
          res[name] = text
        else
          vim.notify(vim.inspect({
            message = "error getting text from buffer",
            buf     = buf,
            file    = vim.api.nvim_buf_get_name(buf),
            error   = text,
          }), vim.log.levels.WARN)
        end
      end

      if res.func == "require" then
        insert(result, res.mod)
      end
    end

    return result
  end
end

local scheduled = false

local function buf_update_handler()
  scheduled = false

  local modnames = {}
  local seen = {}

  local n = #events

  while n > 0 do
    local e = events[n]
    events[n] = nil
    n = n - 1

    local buf = e.buf
    for _, mod in ipairs(get_module_requires(buf) or EMPTY) do
      if not seen[mod] then
        seen[mod] = true
        insert(modnames, mod)
      end
    end

    _M.busy[buf] = nil
  end

  if not resolver then
    return
  end

  ---@type my.lua.resolver.module[]
  local found = {}
  local missing = {}

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

  for _, modname in ipairs(modnames) do
    if not skip[modname] then
      local mod = resolver:find_module(modname)
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

  local settings = _M.settings
  update_settings_from_requires(settings.Lua, found)

  local client = vim.lsp.get_clients({ name = "lua_ls" })[1]
  if not client then
    return
  end

  if not deep_equal(client.settings, settings) then
    update_settings(settings.Lua, client)
  end
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
function _M.on_buf_event(e)
  local buf = e.buf

  if not buf
    or not resolver
    or _M.busy[buf]
    or not WS.meta.lua
    or not vim.api.nvim_buf_is_loaded(buf)
    or not vim.bo[buf].buflisted
    or vim.bo[buf].buftype == "scratch"
    or vim.bo[buf].bufhidden == "hide"
  then
    return
  end

  _M.busy[buf] = true
  insert(events, e)
  schedule_handler()
end

return _M
