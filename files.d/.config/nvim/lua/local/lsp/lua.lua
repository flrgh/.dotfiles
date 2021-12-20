local fs = require 'local.fs'
local mod = require 'local.module'

local stdpath = vim.fn.stdpath
local expand = vim.fn.expand
local split = vim.fn.split
local endswith   = vim.endswith
local insert = table.insert

local EMPTY = {}

local USER_SETTINGS = expand('~/.config/lua/lua-lsp.json')

---@alias local.lsp.filenames string[]

---@class local.lsp.settings
---@field include_vim boolean
---@field third_party? local.lsp.filenames
local DEFAULT_SETTINGS = {

  -- Make the server aware of Neovim runtime files
  include_vim = false,

  ---@class local.lsp.settings.lib : table
  ---@field extra?      local.lsp.filenames
  lib = {
    extra = {},
  },

  ---@class local.lsp.settings.path : table
  ---@field extra? local.lsp.filenames
  path = {
    extra = {},
  },

  third_party = nil,
}

---@param p string
---@return local.lsp.filenames
local function expand_paths(p)
  p = expand(p)
  p = split(p, "\n", false)
  return p
end

---@return local.lsp.filenames
local function packer_dirs()
  local dirs = {}
  mod.if_exists('packer', function()
    local glob = stdpath('data') .. '/site/pack/packer/*/*/lua'
    for _, dir in ipairs(expand_paths(glob)) do
      insert(dirs, dir)
    end
  end)
  return dirs
end

---@param t table
---@param extra table?
---@return table
local function merge(t, extra)
  if type(t) == 'table' and type(extra) == 'table' then
    for k, v in pairs(extra) do
      t[k] = merge(t[k], v)
    end
    return t
  end

  return extra
end

---@return local.lsp.settings
local function load_user_settings()
  local settings = DEFAULT_SETTINGS

  local user = fs.read_json_file(USER_SETTINGS)
  merge(settings, user)

  local root = fs.workspace_root()
  if root then
    local workspace = fs.read_json_file(root .. "/.lua-lsp.json")
    merge(settings, workspace)
  end

  return settings
end

---@param settings local.lsp.settings
local function lua_libs(settings)
  local libs = {}

  if settings.include_vim then
    libs[expand('$VIMRUNTIME/lua')] = true

    for _, dir in ipairs(packer_dirs()) do
      libs[dir] = true
    end
  end

  for _, item in ipairs(settings.lib.extra or EMPTY) do
    for _, elem in ipairs(expand_paths(item)) do
      libs[elem] = true
    end
  end

  libs[expand("$PWD")] = true

  local ws = fs.workspace_root()
  if ws then
    libs[ws] = true
  end

  return libs
end

---@param paths local.lsp.filenames
---@param dir string
local function add_lua_path(paths, dir)
  insert(paths, dir .. '/?.lua')
  insert(paths, dir .. '/?/init.lua')
end

---@param settings local.lsp.settings
---@param libs table<string, boolean>
---@return string[]
local function lua_path(settings, libs)
  local path = split(package.path, ';', false)

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

  for lib in pairs(libs) do
    -- add $path
    add_lua_path(path, lib)

    -- add $path/lua
    if not endswith(lib, '/lua') and fs.dir_exists(lib .. '/lua') then
      add_lua_path(path, lib .. '/lua')
    end

    -- add $path/src
    if not endswith(lib, '/src') and fs.dir_exists(lib .. '/src') then
      add_lua_path(path, lib .. '/src')
    end
  end

  for _, extra in ipairs(settings.path.extra or EMPTY) do
    for _, elem in ipairs(expand_paths(extra)) do
      add_lua_path(path, elem)
    end
  end

  return path
end

local settings = load_user_settings()
local library = lua_libs(settings)
local path = lua_path(settings, library)

-- https://raw.githubusercontent.com/sumneko/vscode-lua/master/setting/schema.json
local conf = {
  cmd = { 'lua-language-server' },
  settings = {
    Lua = {

      runtime = {
        version = 'LuaJIT', -- neovim implies luajit
        path = path,
        pathStrict = false,
      },

      completion = {
        enable = true,
        autoRequire = true,
      },

      signatureHelp = {
        enable = true,
      },

      hover = {
        enable = true,
      },

      hint = {
        enable = true,
      },

      diagnostics = {
        enable = true,
        disable = {
          'lowercase-global',
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
      },
      workspace = {
        library = library,
        ignoreSubmodules = false,
        checkThirdParty = false,
        userThirdParty = settings.third_party,
      },
      telemetry = {
        -- don't phone home
        enable = false,
      },
    },
  }
}

if settings.include_vim then
 mod.if_exists("lua-dev", function(luadev)
   conf = luadev.setup({ lspconfig = conf })
 end)
end

return conf
