if require("local.config.globals").bootstrap then
  return
end

local fs = require 'local.fs'
local mod = require 'local.module'
local globals = require "local.config.globals"

local expand = vim.fn.expand
local endswith   = vim.endswith
local insert = table.insert
local runtime_paths = vim.api.nvim_list_runtime_paths
local dir_exists = fs.dir_exists
local find = string.find

local WORKSPACE = fs.normalize(require("local.config.globals").workspace)

local LUA_PATH = os.getenv("LUA_PATH") or package.path

local EMPTY = {}

---@type string
local USER_SETTINGS = expand("~/.config/lua/lsp.lua")

---@type string
local ANNOTATIONS = globals.git_user_root .. "/lua-type-annotations"

---@type string
local SUMNEKO = expand("~/.local/libexec/lua-language-server/meta/3rd")

local NVIM_LUA = globals.dotfiles.config_nvim_lua

local get_plugin_lua_dir
do
  local dirs

  local function enumerate_plugin_directories()
    dirs = {}

    local plugins = require("lazy").plugins()
    for _, p in ipairs(plugins) do
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


---@class local.lsp.settings
---@field include_vim boolean
---@field third_party string[]
---@field ignore string[]
---@field paths string[]
---@field libraries string[]
local DEFAULT_SETTINGS = {
  -- Make the server aware of Neovim runtime files
  include_vim = false,

  libraries = {},
  paths = {},
  third_party = {},
  ignore = {},
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

---@param p string
---@return string[]
local function expand_paths(p)
  p = p:gsub("$TYPES", ANNOTATIONS)

  if p:find("$SUMNEKO", nil, true) then
    p = p:gsub("$SUMNEKO", SUMNEKO)
    p = p .. "/library"
  end

  p = p:gsub("$DOTFILES_CONFIG_NVIM_LUA", NVIM_LUA)


  return expand(p, nil, true)
end

local _runtime_dirs

---@return string[]
local function runtime_lua_dirs()
  if _runtime_dirs then return _runtime_dirs end
  _runtime_dirs = {}

  for _, dir in ipairs(runtime_paths()) do
    if dir_exists(dir .. "/lua") then
      insert(_runtime_dirs, dir .. "/lua")
    end
  end

  return _runtime_dirs
end

local function append(a, b)
  if type(b) == "table" then
    for _, v in ipairs(b) do
      insert(a, v)
    end
  else
    insert(a, b)
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


---@return local.lsp.settings
local function load_user_settings()
  local settings = DEFAULT_SETTINGS

  local user
  if fs.file_exists(USER_SETTINGS) then
    user = dofile(USER_SETTINGS)
  end

  local base = fs.basename(WORKSPACE)

  for ws, conf in pairs(user.workspaces or {}) do
    if ws == base or
       ws == "*" or
       find(base, ws, nil, true)
    then
      imerge(settings.libraries, conf.libraries)
      imerge(settings.paths, conf.paths)
      imerge(settings.ignore, conf.ignore)
      if conf.include_vim then
        settings.include_vim = true
      end
    end
  end

  if base == ".dotfiles" or base == "dotfiles" then
    settings.include_vim = true
  end

  return settings
end

local plugin_libs = {
  "nvim-cmp",
  "lazy.nvim",
  "nvim-lspconfig",
  "lspsaga.nvim",
  "hover.nvim",
  "lualine.nvim",
  "lspkind-nvim",
  "neodev",
  "nvim-treesitter",
  "telescope",
}

---@param settings local.lsp.settings
local function lua_libs(settings)
  local libs = {}

  for _, item in ipairs(settings.libraries or EMPTY) do
    for _, elem in ipairs(expand_paths(item)) do
      elem = fs.normalize(elem)
      if elem ~= WORKSPACE then
        insert(libs, elem)
      end
    end
  end

  if settings.include_vim then
    insert(libs, expand("$VIMRUNTIME/lua"))

    if mod.exists("neodev.sumneko") then
      local sumneko = require "neodev.sumneko"

      if type(sumneko.library) == "function" then
        append(libs, sumneko.library({
          library = {
            types = true,
          }
        }))

      else
        vim.notify("function `neodev.sumneko.library()` is missing")
      end

    else
      vim.notify("module `neodev.sumneko` is missing")
    end

    if ANNOTATIONS and dir_exists(ANNOTATIONS) then
      insert(libs, ANNOTATIONS .. "/luv")
      insert(libs, ANNOTATIONS .. "/neovim")
    end

    for _, name in ipairs(plugin_libs) do
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

---@param settings local.lsp.settings
---@param libs table<string, boolean>
---@return string[]
local function lua_path(settings, libs)
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

  for _, extra in ipairs(settings.paths or EMPTY) do
    for _, elem in ipairs(expand_paths(extra)) do
      add_lua_path(paths, elem)
    end
  end

  if settings.include_vim then
    add_lua_path(paths, expand("$VIMRUNTIME/lua"))
    for _, p in ipairs(runtime_lua_dirs()) do
      add_lua_path(paths, p)
    end
  end

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

  ---@diagnostic disable-next-line
  LUA_PATH:gsub("[^;]+", function(path)
    path = fs.normalize(path)
    local dir = path:gsub("%?%.lua$", ""):gsub("%?/init%.lua$", "")

    if path ~= "" and
       path ~= "/" and
       dir ~= WORKSPACE
    then
      insert(paths, path)
    end
  end)

  return dedupe(paths, true)
end

local settings = load_user_settings()
local library = lua_libs(settings)
local path = lua_path(settings, library)

local conf = {
  cmd = { 'lua-language-server' },
  settings = {
    ---@type sumneko.setting
    Lua = {
      runtime = {
        fileEncoding = "utf8",
        nonstandardSymbol = {},
        path = path,
        pathStrict = false,
        unicodeName = true,
        version = 'LuaJIT',
        special = {
          ["local.module.reload"] = "require",
          ["local.module.if_exists"] = "require",
        },

      },

      completion = {
        enable = true,
        autoRequire = true,
        callSnippet = "Disable",
        displayContext = 0,
        keywordSnippet = "Replace",
        postfix = "@",
        requireSeparator = ".",
        showParams = true,
        showWord = "Fallback",
        workspaceWord = true,
      },

      signatureHelp = {
        enable = true,
      },

      hover = {
        enable = true,
        enumsLimit = 5,
        previewFields = 20,
        viewNumber = true,
        viewString = true,
        viewStringMax = 1000,
        expandAlias = true,

      },

      hint = {
        enable = true,
        paramName = "All",
        paramType = true,
        setType = true,
        arrayIndex = "Enable",
        await = false,
      },

      IntelliSense = {
        -- https://github.com/sumneko/lua-language-server/issues/872
        traceLocalSet    = true,
        traceReturn      = true,
        traceBeSetted    = true,
        traceFieldInject = true,
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

        ignoredFiles = "Opened",
        libraryFiles = "Opened",
        workspaceDelay = 3000,
        workspaceRate = 80,

      },

      workspace = {
        checkThirdParty = false,
        ignoreDir = settings.ignore,
        ignoreSubmodules = false,
        library = library,
        useGitIgnore = true,
        userThirdParty = settings.third_party,
      },

      semantic = {
        annotation = true,
        enable = true,
        variable = true,
      },

      telemetry = {
        enable = true,
      },

      type = {
        castNumberToInteger = true,
        weakUnionCheck = true,
      },
    },
  }
}

return conf
