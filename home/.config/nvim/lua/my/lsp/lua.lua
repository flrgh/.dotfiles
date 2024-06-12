if require("my.config.globals").bootstrap then
  return
end

local fs = require "my.utils.fs"
local mod = require "my.utils.module"
local globals = require "my.config.globals"
local plugin = require "my.utils.plugin"

local endswith   = vim.endswith
local insert = table.insert
local find = string.find
local EMPTY = {}

local WORKSPACE = fs.normalize(globals.workspace)

---@type string[]
local LUA_PATH_ENTRIES = {}
do
  local lua_path = os.getenv("LUA_PATH") or package.path
  ---@diagnostic disable-next-line
  lua_path:gsub("[^;]+", function(path)
    path = fs.normalize(path)
    local dir = path:gsub("%?%.lua$", ""):gsub("%?/init%.lua$", "")

    if path ~= "" and
       path ~= "/" and
       dir ~= WORKSPACE
    then
      insert(LUA_PATH_ENTRIES, path)
    end
  end)
end

--- annotations from https://github.com/LuaCATS
local LUA_CATS = globals.git_root .. "/LuaCATS"

local LUA_TYPE_ANNOTATIONS = globals.git_user_root .. "/lua-type-annotations"

---@type my.lsp.settings
local SETTINGS_COMMON = {
  libraries = {
    LUA_TYPE_ANNOTATIONS .. "/Penlight",
    LUA_TYPE_ANNOTATIONS .. "/LuaFileSystem",
    LUA_TYPE_ANNOTATIONS .. "/luasocket",
    globals.git_user_root .. "/lua-utils/lib",
  },
}

---@type my.lsp.settings
local SETTINGS_RESTY = {
  libraries = {
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
}

---@type my.lsp.settings
local SETTINGS_KONG = {
  libraries = {
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


---@type table<string, my.lsp.settings>
local WORKSPACES = {
  [".dotfiles"] = {
    nvim = true,
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
  },

  doorbell = {
    resty = true,
  },

  kong = {
    resty = true,
    kong  = true,
  },

  ["kong-ee"] = {
    resty = true,
    kong  = true,
  },

  ngx = {
    resty = true,
  },

  nginx = {
    resty = true,
  },

  resty = {
    resty = true,
  },
}

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
---@field ignore? string[]
---@field libraries? string[]
---@field plugins? string[]
---@field nvim? boolean
---@field kong? boolean
---@field resty? boolean
local DEFAULT_SETTINGS = {
  libraries = {},
  ignore = {},
  plugins = {},
  nvim = false,
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
  imerge(current.ignore, extra.ignore)
  imerge(current.plugins, extra.plugins)

  current.nvim  = current.nvim or extra.nvim
  current.resty = current.resty or extra.resty
  current.kong  = current.kong or extra.kong
end

---@return my.lsp.settings
local function workspace_settings()
  local settings = DEFAULT_SETTINGS

  local base = fs.basename(WORKSPACE)

  for ws, conf in pairs(WORKSPACES) do
    if ws == base or
       ws == "*" or
       find(base, ws, nil, true)
    then
      merge_settings(settings, conf)

      if conf.nvim then
        merge_settings(settings, SETTINGS_NVIM)
      end

      if conf.resty then
        merge_settings(settings, SETTINGS_RESTY)
      end

      if conf.kong then
        merge_settings(settings, SETTINGS_KONG)
      end
    end
  end

  return settings
end

---@param settings my.lsp.settings
local function lua_libs(settings)
  local libs = {}

  for _, path in ipairs(settings.libraries or EMPTY) do
    path = fs.normalize(path)
    if path ~= WORKSPACE then
      insert(libs, path)
    end
  end

  extend(libs, SETTINGS_COMMON.libraries)

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

---@param libs table<string, boolean>
---@return string[]
local function lua_path(libs)
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

  for _, lib in ipairs(libs) do
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

  extend(paths, LUA_PATH_ENTRIES)

  return dedupe(paths, true)
end

local Disable = "Disable"
local Replace = "Replace"
local Fallback = "Fallback"
local Opened = "Opened"

local function init()
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
          path              = lua_path({}),
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

local function setup()
  local ws = workspace_settings()
  local library = lua_libs(ws)

  return {
    Lua = {
      runtime = {
        path = lua_path(library),
      },

      workspace = {
        ignoreDir = ws.ignore,
        library = library,
      }
    }
  }
end

return {
  setup = setup,
  init = init,
}
