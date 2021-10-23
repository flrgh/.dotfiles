local fs = require 'local.fs'

local expand = vim.fn.expand
local split = vim.fn.split
local insert = table.insert
local EMPTY = {}

local SERVER = 'lua-language-server'
local USER_SETTINGS = expand('~/.config/lua/lua-lsp.json')

---@class local.lsp.lua.settings
local DEFAULT_SETTINGS = {
  lib = {
    include_vim = false, -- Make the server aware of Neovim runtime files
    extra = {},
  },
  path = {
    extra = {},
  },
  log_level = 2,
  third_party = nil,
}

---@param p string
---@return string[]
local function expand_paths(p)
  p = expand(p)
  p = split(p, "\n")
  return p
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

---@return local.lsp.lua.settings
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

---@param settings local.lsp.lua.settings
local function lua_libs(settings)
  local opts = settings.lib
  local libs = {}
  if opts.include_vim then
    libs[expand('$VIMRUNTIME/lua')] = true
    libs[expand('$VIMRUNTIME/lua/vim/lsp')] = true
    libs[expand('$HOME/.config/nvim/lua')] = true
  end

  for _, item in ipairs(opts.extra) do
    for _, elem in ipairs(expand_paths(item)) do
      libs[elem] = true
    end
  end

  libs[expand("$PWD")] = true
  libs[expand("$PWD/lua")] = true
  libs[expand("$PWD/src")] = true

  return libs
end

---@param settings local.lsp.lua.settings
---@param libs table<string, boolean>
---@return string[]
local function lua_path(settings, libs)
  local path = vim.split(package.path, ';')

  for lib in pairs(libs) do
    insert(path, lib .. '/?.lua')
    insert(path, lib .. '/?/init.lua')
  end

  for _, extra in ipairs(settings.path.extra or EMPTY) do
    for _, elem in ipairs(expand_paths(extra)) do
      insert(path, elem .. '/?.lua')
      insert(path, elem .. '/?/init.lua')
    end
  end

  return path
end

return function(on_attach, lsp, caps)
  if not vim.fn.executable(SERVER) then
    return
  end

  local settings = load_user_settings()
  local library = lua_libs(settings)
  local path = lua_path(settings, library)

  -- https://github.com/sumneko/vscode-lua/blob/master/setting/schema.json
  lsp.sumneko_lua.setup {
    on_attach = on_attach,
    capabilities = caps,
    cmd = { SERVER },
    log_level = settings.log_level,
    settings = {
      Lua = {
        runtime = {
          version = 'LuaJIT', -- neovim implies luajit
          path = path,
        },
        completion = {
          enable = true,
        },
        signatureHelp = {
          enable = true,
        },
        hover = {
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
    },
  }
end
