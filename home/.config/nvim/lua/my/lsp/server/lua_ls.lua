if require("my.config.globals").bootstrap then
  return
end

local _M = {}

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

---@type my.lsp.settings
local SETTINGS_NVIM = {
  libraries = {
    globals.dotfiles.config_nvim_lua,
    globals.nvim.runtime_lua,
  },
  plugins = {
--    "LuaSnip",
--    "hover.nvim",
    "lazy.nvim",
--    "lspkind-nvim",
--    "lspsaga.nvim",
--    "lualine",
--    "lualine.nvim",
--    "neodev",
    "nvim-cmp",
    "nvim-lspconfig",
--    "nvim-notify",
--    "nvim-treesitter",
--    "telescope",
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
        table.insert(client.workspace_folders, {
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

local get_plugin_lua_dir
do
  local dirs

  local function enumerate_plugin_directories()
    dirs = {}

    for _, p in ipairs(plugin.list()) do
      local name = p.name
      local lua_dir = p.dir .. "/lua"
      dirs[name] = lua_dir

      -- normalized, for convenience
      name = name:gsub("[%-_.]*nvim[%-_.]*", "")
      if name ~= "" then
        dirs[name] = lua_dir

        name = name:lower()
        dirs[name] = lua_dir

        name = name:gsub("[%-._]", "")
        dirs[name] = lua_dir
      end
    end
  end

  ---@param name string
  ---@return string|nil
  function get_plugin_lua_dir(name)
    if not dirs then enumerate_plugin_directories() end
    return dirs[name]
  end
end


---@class my.lsp.settings
---@field ignore?           string[]
---@field libraries?        string[]
---@field definitions?      string[]
---@field plugins?          string[]
---@field luarc_settings?   my.lsp.LuaLS
---@field override_all?     boolean
---@field luarocks?         boolean
local DEFAULT_SETTINGS = {
  libraries = {},
  ignore = {},
  plugins = {},
  definitions = {},
  luarc = false,
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

  if WS.meta.luarc then
    settings.luarc = true
    local fname = fs.join(WS.dir, ".luarc.json")
    settings.luarc_settings = fs.load_json_file(fname)
    return settings
  end

  merge_settings(settings, SETTINGS_COMMON)

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
local function add_lua_path(paths, dir)
  if dir then
    insert(paths, dir .. '/?.lua')
    insert(paths, dir .. '/?/init.lua')
  end
end

---@param settings my.lsp.settings
---@return string[]
local function runtime_paths(settings)
  local paths = {}

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
    add_lua_path(paths, lib)

    -- add $path/lua
    if not endswith(lib, '/lua') and fs.dir_exists(lib .. '/lua') then
      add_lua_path(paths, lib .. '/lua')
    end

    -- add $path/src
    if not endswith(lib, '/src') and fs.dir_exists(lib .. '/src') then
      add_lua_path(paths, lib .. '/src')
    end

    -- add $path/lib
    if not endswith(lib, '/lib') and fs.dir_exists(lib .. '/lib') then
      add_lua_path(paths, lib .. '/lib')
    end
  end

  for _, dir in ipairs(LUA_PATH_ENTRIES) do
    add_lua_path(paths, dir)
  end

  return dedupe(paths, true)
end

local Disable = "Disable"
local Replace = "Replace"
local Fallback = "Fallback"
local Opened = "Opened"

---@type my.lua.resolver.module[]
local requires

local function find_requires()
  if WS.meta.luarc then
    return
  end

  local cmd = {
    "rg",
    "--one-file-system",
    "--hidden",
    "--no-heading",
    "--no-line-number",
    "--no-filename",
    "-g", "*.lua",
    "-e", [[require[ \(]*['"\[=]+([a-zA-Z0-9._/-]+)['"\]=]+[ \)]*]],
    "-r", "$1",
    "-o",
  }

  local req = {}
  local seen = {}
  local n = 0

  ---@type my.lua.resolver.module[]
  local found = {}

  local done = false

  local function have_items()
    return n > 0
  end

  local meta

  local ws = get_merged_settings()

  meta = { source = SRC_TYPE_DEFS }
  for _, dir in ipairs(ws.definitions or {}) do
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

  local skipped = 0

  ---@param modname string
  local function resolve_req(modname)
    if not paths then return end

    if skip[modname] or modname:sub(-1) == "." then
      skipped = skipped + 1
      return
    end

    if resolver then
      local res = resolver:find_module(modname)
      if res then
        table.insert(found, res)

      else
        table.insert(missing, modname)
      end

      return
    end
  end

  local mods = 0

  local function resolve()
    while true do
      vim.wait(10, have_items)
      while n > 0 do
        ---@type string
        local item = req[n]
        n = n - 1
        resolve_req(item)
      end

      if done then
        break
      end
    end

    requires = found
  end

  local scheduled = false

  local function add_req(line)
    if not seen[line] then
      mods = mods + 1
      seen[line] = true
      n = n + 1
      req[n] = line

      if not scheduled then
        scheduled = true
        vim.defer_fn(resolve, 0)
      end
    end
  end

  vim.system(cmd,
    {
      text = true,
      stdout = function(err, data)
        if err then
          vim.notify("Error: " .. err)
          return
        end

        if data then
          data:gsub("[^\r\n]+", add_req)
        end
      end,
      timeout = 1000 * 5,
    },
    function(_out)
      done = true
    end
  )
end

---@param settings my.lsp.LuaLS
---@param found my.lua.resolver.module[]
local function update_settings_from_requires(settings, found)
  paths = settings.runtime.path
  libraries = settings.workspace.library

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

---@return lspconfig.Config
function _M.init()
  if WS.meta.lua then
    vim.defer_fn(find_requires, 1)
  end

  local settings = get_merged_settings()

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
      runtime = {
        version           = "LuaJIT",
        builtin           = "enable",
        fileEncoding      = "utf8",
        nonstandardSymbol = {},
        pathStrict        = true,
        unicodeName       = false,
        path              = runtime_paths({}),
        plugin            = nil,
        pluginArgs        = nil,
        special = {
          ["my.utils.luamod.reload"] = "require",
          ["my.utils.luamod.if_exists"] = "require",
        },
      },

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

      signatureHelp = {
        enable = true,
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

      hint = {
        enable     = true,
        paramName  = "All",
        paramType  = true,
        setType    = true,
        arrayIndex = "Enable",
        await      = false,
        semicolon  = Disable,
      },

      IntelliSense = {
        -- https://github.com/sumneko/lua-language-server/issues/872
        traceLocalSet    = true,
        traceReturn      = true,
        traceBeSetted    = true,
        traceFieldInject = true,
      },

      format = {
        enable = false,
      },

      diagnostics = {
        enable = true,
        disable = {
          'lowercase-global',
          'need-check-nil',
        },

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
        workspaceRate = 80,
        workspaceEvent = "OnSave",

        groupFileStatus = nil,

        unusedLocalExclude = {
          "self",
        },

        neededFileStatus = {
          ["ambiguity-1"]            = Opened,
          ["assign-type-mismatch"]   = Opened,
          ["await-in-sync"]          = "None!",
          ["cast-local-type"]        = Opened,
          ["cast-type-mismatch"]     = Opened,
          ["circle-doc-class"]       = Opened,
          ["close-non-object"]       = Opened,
          ["code-after-break"]       = Opened,
          ["codestyle-check"]        = "None!",
          ["count-down-loop"]        = Opened,
          deprecated                 = Opened,
          ["different-requires"]     = Opened,
          ["discard-returns"]        = Opened,
          ["doc-field-no-class"]     = Opened,
          ["duplicate-doc-alias"]    = Opened,
          ["duplicate-doc-field"]    = Opened,
          ["duplicate-doc-param"]    = Opened,
          ["duplicate-index"]        = Opened,
          ["duplicate-set-field"]    = Opened,
          ["empty-block"]            = Opened,
          ["global-in-nil-env"]      = Opened,
          ["lowercase-global"]       = "None!",
          ["missing-parameter"]      = Opened,
          ["missing-return"]         = Opened,
          ["missing-return-value"]   = Opened,
          ["need-check-nil"]         = Opened,
          ["newfield-call"]          = Opened,
          ["newline-call"]           = Opened,
          ["no-unknown"]             = "None!",
          ["not-yieldable"]          = "None!",
          ["param-type-mismatch"]    = Opened,
          ["redefined-local"]        = Opened,
          ["redundant-parameter"]    = Opened,
          ["redundant-return"]       = Opened,
          ["redundant-return-value"] = Opened,
          ["redundant-value"]        = Opened,
          ["return-type-mismatch"]   = Opened,
          ["spell-check"]            = "None!",
          ["trailing-space"]         = Opened,
          ["unbalanced-assignments"] = Opened,
          ["undefined-doc-class"]    = Opened,
          ["undefined-doc-name"]     = Opened,
          ["undefined-doc-param"]    = Opened,
          ["undefined-env-child"]    = Opened,
          ["undefined-field"]        = Opened,
          ["undefined-global"]       = Opened,
          ["unknown-cast-variable"]  = Opened,
          ["unknown-diag-code"]      = Opened,
          ["unknown-operator"]       = Opened,
          ["unreachable-code"]       = Opened,
          ["unused-function"]        = Opened,
          ["unused-label"]           = Opened,
          ["unused-local"]           = Opened,
          ["unused-vararg"]          = Opened,
        }
      },

      workspace = {
        checkThirdParty  = Disable,
        ignoreSubmodules = true,
        library          = {},
        useGitIgnore     = true,
        userThirdParty   = nil,
      },

      semantic = {
        annotation = true,
        enable     = true,
        keyword    = true,
        variable   = true,
      },

      type = {
        castNumberToInteger = true,
        weakUnionCheck      = true,
        weakNilCheck        = true,
      },
    }
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

  client_attached[client.id] = true

  local start = vim.uv.now()

  local ws = get_merged_settings()

  if ws.luarc_settings then
    return
  end

  vim.defer_fn(function()
    local settings = {
      Lua = nil,
    }

    local library = workspace_libraries(ws)

    settings.Lua = {
      runtime = {
        path = runtime_paths(library),
      },

      workspace = {
        ignoreDir = ws.ignore,
        library = library,
      }
    }

    local defaults = (ws.override_all and {}) or client.settings
    local new = tbl_deep_extend("force", defaults, settings)

    local function have_requires()
      return requires ~= nil
    end

    if vim.wait(5000, have_requires, 10) then
      update_settings_from_requires(new.Lua, requires)
    end

    _M.settings = new

    vim.defer_fn(find_requires, 1)

    if not deep_equal(client.settings, new) then
      update_settings(new.Lua, client)
    end

    local duration = vim.uv.now() - start
    vim.notify(("loaded lua things in %s ms"):format(duration))
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
    table.insert(cmd, globals.nvim.plugins)
  end

  for _, lib in ipairs(LUA_PATH_ENTRIES) do
    table.insert(cmd, lib)
  end

  vim.system(cmd, { text = true }, function(out)
    local results = {}
    local _ = out.stdout:gsub("[^\r\n]+", function(line)
      table.insert(results, line)
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

return _M
