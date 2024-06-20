if require("my.config.globals").bootstrap then
  return
end

local _M = {}

local fs = require "my.utils.fs"
local mod = require "my.utils.module"
local globals = require "my.config.globals"
local plugin = require "my.utils.plugin"

local endswith = vim.endswith
local insert = table.insert
local find = string.find
local deepcopy = vim.deepcopy
local tbl_deep_extend = vim.tbl_deep_extend
local deep_equal = vim.deep_equal

local EMPTY = {}

local WORKSPACE = fs.normalize(globals.workspace)

---@type string[]
local LUA_PATH_ENTRIES = {}
do
  local lua_path = os.getenv("LUA_PATH") or package.path or ""

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
       and dir ~= WORKSPACE
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
    "LuaSnip",
    "hover.nvim",
    "lazy.nvim",
    "lspkind-nvim",
    "lspsaga.nvim",
    "lualine",
    "lualine.nvim",
    "neodev",
    "nvim-cmp",
    "nvim-lspconfig",
    "nvim-notify",
    "nvim-treesitter",
    "telescope",
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


---@class my.lsp.workspace.matcher
---
---@field dir?       string
---@field path_match? string
---@field settings   my.lsp.settings

---@type my.lsp.workspace.matcher[]
local WORKSPACES = {
  {
    dir = ".dotfiles",
    settings = {
      nvim = true,
    },
  },

  {
    path_match = ".dotfiles",
    settings = {
      nvim = true,
    },
  },

  {
    dir = "doorbell",
    settings = {
      resty = true,
      definitions = {
        globals.git_user_root .. "/lua-resty-pushover/lib",
      },
    },
  },

  {
    dir = "kong",
    settings = {
      resty = true,
      kong = true,
    },
  },

  {
    dir = "kong-ee",
    settings = {
      resty = true,
      kong = true,
    },
  },

  {
    path_match = "ngx",
    settings = {
      resty = true,
    },
  },

  {
    path_match = "nginx",
    settings = {
      resty = true,
    },
  },

  {
    path_match = "resty",
    settings = {
      resty = true,
    },
  },

  {
    dir = "lua-language-server",
    settings = {
      luarc = true,
      override_all = true,
    },
  },

  {
    path_match = "nvim",
    settings = {
      nvim = true,
    },
  },

  {
    path_match = "neovim",
    settings = {
      nvim = true,
    },
  },
}

-- prioritize exact directory matches
table.sort(WORKSPACES, function(a, b)
  if a.dir then
    if b.dir then
      return #a.dir > #b.dir
    end

    return true

  elseif b.dir then
    return false
  end

  return #a.path_match > #b.path_match
end)

---@param t string[]
---@param extra string|string[]
local function extend(t, extra)
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
---@field nvim?             boolean
---@field kong?             boolean
---@field resty?            boolean
---@field luarc?            boolean
---@field luarc_settings?   table
---@field override_all?     boolean
---@field luarocks?         boolean
local DEFAULT_SETTINGS = {
  libraries = {},
  ignore = {},
  plugins = {},
  definitions = {},
  nvim = false,
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
---@param dir string
local function merge_settings(current, extra, dir)
  imerge(current.libraries, extra.libraries)
  imerge(current.definitions, extra.definitions)
  imerge(current.ignore, extra.ignore)
  imerge(current.plugins, extra.plugins)

  current.nvim  = current.nvim or extra.nvim
  current.resty = current.resty or extra.resty
  current.kong  = current.kong or extra.kong
  current.luarocks  = current.luarocks or extra.luarocks

  if extra.luarc then
    current.luarc = extra.luarc
    local fname = fs.join(dir, ".luarc.json")
    current.luarc_settings = fs.load_json_file(fname)
  end

  if extra.nvim then
    merge_settings(current, SETTINGS_NVIM, dir)
  end

  if extra.resty then
    merge_settings(current, SETTINGS_RESTY, dir)
  end

  if extra.kong then
    merge_settings(current, SETTINGS_KONG, dir)
  end
end

---@param subject string
---@param match   string
---@return boolean
local function is_substr(subject, match)
  return type(subject) == "string"
     and type(match) == "string"
     and find(subject, match, nil, true)
end


---@param dir? string
---@return my.lsp.settings
---@return my.lsp.workspace.matcher? matched
local function workspace_settings(dir)
  local settings = DEFAULT_SETTINGS
  local matched

  dir = dir or WORKSPACE

  local basename = assert(fs.basename(dir))

  for _, ws in ipairs(WORKSPACES) do
    if ws.dir == basename
       or is_substr(dir, ws.path_match)
    then
      settings = deepcopy(settings)
      matched = ws
      merge_settings(settings, ws.settings, dir)
      break
    end
  end

  return settings, matched
end

---@param settings my.lsp.settings
---@return string[]
local function workspace_libraries(settings)
  local libs = {}

  for _, path in ipairs(settings.libraries or EMPTY) do
    path = fs.normalize(path)
    if path ~= WORKSPACE then
      insert(libs, path)
    end
  end

  for _, path in ipairs(settings.definitions or EMPTY) do
    path = fs.normalize(path)
    if path ~= WORKSPACE then
      insert(libs, path)
    end
  end

  extend(libs, SETTINGS_COMMON.libraries)
  extend(libs, SETTINGS_COMMON.definitions)

  if settings.nvim then
    if mod.exists("neodev.config") then
      local nconf = require "neodev.config"
      insert(libs, nconf.root() .. "/types/stable")
    else
      vim.notify("module `neodev.config` is missing")
    end

    for _, name in ipairs(settings.plugins or EMPTY) do
      local lib = get_plugin_lua_dir(name)
      if lib then
        insert(libs, lib)
      end
    end
  end

  if settings.luarocks then
    -- luarocks config deploy_lua_dir
    local res = vim.system({ "luarocks", "config", "deploy_lua_dir" },
                           { text = true }
                          ):wait()

    local stdout = res and res.stdout and #res.stdout > 0 and res.stdout
    if stdout then
      stdout = vim.trim(stdout)
      insert(libs, stdout)
    end
  end

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

---@return lspconfig.Config
function _M.init()
  local ws, matched = workspace_settings()
  _M.workspace = matched

  if ws.luarc_settings then
    return {
      cmd = { 'lua-language-server' },
      settings = {
        Lua = ws.luarc_settings,
      },
    }
  end

  return {
    cmd = { 'lua-language-server' },
    settings = {
      Lua = {
        runtime = {
          version           = "LuaJIT",
          builtin           = "enable",
          fileEncoding      = "utf8",
          nonstandardSymbol = {},
          pathStrict        = false,
          unicodeName       = false,
          path              = runtime_paths({}),
          plugin            = nil,
          pluginArgs        = nil,
          special = {
            ["my.utils.module.reload"] = "require",
            ["my.utils.module.if_exists"] = "require",
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
          ignoreSubmodules = false,
          library          = nil,
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
      },
    }
  }

end

---@param client vim.lsp.Client
---@param buf integer
function _M.on_attach(client, buf)
  local ws, matched = workspace_settings(client and client.config and client.config.root_dir)
  _M.workspace = matched

  local settings = {
    Lua = nil,
  }

  if ws.luarc_settings then
    settings.Lua = ws.luarc_settings

  else
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
  end

  local defaults = (ws.override_all and {}) or client.settings
  local new = tbl_deep_extend("force", defaults, settings)

  if not deep_equal(client.settings, new) then
    vim.notify("Updating LuaLS settings...")
    client.settings = new
    client.notify("workspace/didChangeConfiguration", new)
  end
end

return _M
