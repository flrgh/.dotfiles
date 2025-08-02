---@class my.workspace : table
---
---@field dir string # fully-qualified workspace directory path
---@field basename string # last path element of the workspace
---@field meta my.workspace.meta
local WS = {}


local fs = require "my.utils.fs"
local const = require "my.constants"

--- annotations from https://github.com/LuaCATS
local LUA_CATS = const.git_root .. "/LuaCATS"
local LUA_TYPE_ANNOTATIONS = const.git_user_root .. "/lua-type-annotations"


local insert = table.insert

---@alias my.workspace.meta table<string, any>

---@alias my.workspace.matcher fun(ws: my.workspace):boolean|nil


---@param subject string
---@param sub string
---@return boolean
local function substr(subject, sub)
  return subject:find(sub, nil, true) ~= nil
end

local function extend(ws, key, elems)
  ws.meta[key] = ws.meta[key] or {}
  local seen = {}
  for _, v in pairs(ws.meta[key]) do
    seen[v] = true
  end

  for _, elem in ipairs(elems) do
    if not seen[elem] then
      seen[elem] = true
      insert(ws.meta[key], elem)
    end
  end
end


---@param ws my.workspace
local function include_busted(ws)
  ws.meta.lua = true
  ws.meta.busted = true
  extend(ws, "lua.definitions", {
    LUA_TYPE_ANNOTATIONS .. "/say",
    LUA_TYPE_ANNOTATIONS .. "/mediator",

    LUA_CATS .. "/busted" .. "/library",
    LUA_CATS .. "/luassert" .. "/library",
  })
end


---@param ws my.workspace
local function include_resty(ws)
  ws.meta.lua = true
  ws.meta.resty = true
  extend(ws, "lua.definitions", {
    LUA_CATS .. "/openresty/library",
    const.git_user_root .. "/resty-community-typedefs/library",
  })
end


---@param ws my.workspace
local function include_nvim(ws)
  ws.meta.lua = true
  ws.meta.nvim = true

  extend(ws, "lua.libraries", {
    const.nvim.runtime_lua,
  })

  extend(ws, "lua.definitions", {
    LUA_CATS .. "/luv/library",
  })

  extend(ws, "lua.ignore", {
    "lspconfig/server_configurations"
  })
end


---@type my.workspace.matcher[]
local matchers = {
  -- ./.busted
  function(ws)
    if fs.file_exists(fs.join(ws.dir, ".busted")) then
      include_busted(ws)
    end
  end,

  -- doorbell
  function(ws)
    if ws.dir ~= const.git_user_root .. "/doorbell" then
      return
    end

    ws.meta.lua = true
    ws.meta.doorbell = true
    include_busted(ws)
    include_resty(ws)
  end,

  -- ~/git/.dotfiles
  function(ws)
    if ws.dir ~= const.dotfiles.root then
      return
    end

    ws.meta.dotfiles = true

    ws.meta["lua.root_dir"] = const.dotfiles.config_nvim
    extend(ws, "lua.libraries", {
      const.dotfiles.config_nvim_lua,
    })

    extend(ws, "lua.plugins", {
      "lazy.nvim",
      "nvim-cmp",
      "nvim-lspconfig",
      "blink.cmp",
    })

    include_nvim(ws)
  end,


  -- anything to do with OpenResty
  function(ws)
    if substr(ws.dir, "resty")
      or substr(ws.dir, "ngx")
      or substr(ws.dir, "nginx")
      or substr(ws.dir, "OpenResty")
    then
      include_resty(ws)
    end
  end,

  -- ~/git/kong/*
  function(ws)
    local check = const.git_root .. "/kong"
    if ws.dir:find(check, nil, true) == 1 then
      include_resty(ws)

      extend(ws, "lua.definitions", {
        LUA_TYPE_ANNOTATIONS .. "/kong",
        LUA_TYPE_ANNOTATIONS .. "/lua_pack",
      })

      extend(ws, "lua.ignore", {
        -- kong-build-tools
        ".kbt",

        -- busted test files
        "*_spec.lua",

        -- kong migration files
        "migrations/[0-9]*.lua",
        "migrations/**/[0-9]*.lua",

        -- local openresty build dir
        ".resty",
      })
    end
  end,

  -- lua_ls
  function(ws)
    if ws.basename == "lua-language-server" then
      ws.meta.lua = true
      ws.meta.luarc = true
      return true
    end
  end,

  -- neovim
  function(ws)
    if substr(ws.dir, "neovim") or substr(ws.dir, "nvim") then
      include_nvim(ws)
    end
  end,

  -- blj
  function(ws)
    if substr(ws.dir, "blj") then
      ws.meta.lua = true
      extend(ws, "lua.libraries", {
        const.git_user_root .. "/blj/lua",
      })
    end
  end,
}

if not WS.dir then
  local dir = assert(const.workspace)
  assert(fs.dir_exists(dir))

  WS.dir = assert(fs.realpath(dir))
  WS.basename = fs.basename(dir)
  WS.meta = {}
  WS.lsp = {}

  for i = 1, #matchers do
    if matchers[i](WS) then
      break
    end
  end
end

return WS
