local _M = {}

local user_const = require("my.constants")
local const = require("my.lsp.lua_ls.constants")
local luamod = require("my.utils.luamod")

local utils = require("my.utils")
local fs = utils.fs
local plugin = utils.plugin
local contains = utils.string.contains
local find = string.find
local sub = string.sub


local TYPE_DIR = const.LUA_TYPE_ANNOTATIONS
local EMPTY = {}


local PLUGINS = {
  "lazy.nvim",
  "nvim-cmp",
  "nvim-lspconfig",
  "blink.cmp",
}

local MODS = {
  say = {
    type_defs = {
      TYPE_DIR .. "/say",
    },
  },

  doorbell = {
    include = {
      "resty",
      "busted",
    },
  },

  mediator = {
    type_defs = {
      TYPE_DIR .. "/mediator",
    },
  },

  busted = {
    type_defs = {
      const.LUA_CATS .. "/busted/library",
    },
    include = {
      "luassert",
      "say",
      "mediator",
    },
  },

  luassert = {
    type_defs = {
      const.LUA_CATS .. "/luassert/library",
    },
  },

  pl = {
    type_defs = {
      TYPE_DIR .. "/penlight",
    },
  },

  lfs = {
    type_defs = {
      TYPE_DIR .. "/lfs",
    },
  },

  lfs_ffi = {
    include = {
      "lfs",
    },
  },

  luasocket = {
    type_defs = {
      TYPE_DIR .. "/luasocket",
    },
  },

  socket = {
    include = {
      "luasocket",
    },
  },

  ltn12 = {
    include = {
      "luasocket",
    },
  },

  luv = {
    type_defs = {
      TYPE_DIR .. "/luv",
    },
  },

  uv = {
    include = {
      "luv",
    },
  },

  neovim = {
    type_defs = {
      TYPE_DIR .. "/neovim",
    },
    include = {
      "uv",
      user_const.nvim.runtime_lua,
    },

    ignore = {
      "lspconfig/server_configurations"
    },
  },

  vim = {
    include = {
      "neovim",
    },
  },

  nvim = {
    include = {
      "neovim",
    },
  },

  cjson = {
    type_defs = {
      TYPE_DIR .. "/cjson",
    },
  },

  resty = {
    type_defs = {
      const.LUA_CATS .. "/openresty/library",
      const.LUA_RESTY_COMMUNITY .. "/library",
    },
    include = {
      "cjson",
    },
  },

  lua_pack = {
    type_defs = {
      TYPE_DIR .. "/lua_pack",
    },
  },

  kong = {
    type_defs = {
      TYPE_DIR .. "/kong",
    },
    include = {
      "resty",
      "lua_pack",
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
    },
  },
}


---@param name string
---@return boolean
local function is_path(name)
  return name:sub(1, 1) == "/"
end


---@param dir string
---@param config my.lua_ls.Config
---@return boolean
local function add_lib(dir, config)
  if fs.dir_exists(dir) then
    config:add_library(dir)
    return true
  end
  return false
end


---@param name string
---@param config my.lua_ls.Config
---@param seen? table
local function add_mod(name, config, seen)
  if is_path(name) then
    return add_lib(name, config)
  end

  local dot = find(name, ".", nil, true)
  if dot and dot > 1 then
    name = sub(name, 1, dot - 1)
  end
  if name == "" then
    return
  end

  if config.modules:contains(name) then
    return
  end

  config.modules:add(name)

  local dir = TYPE_DIR .. "/" .. name
  if fs.dir_exists(dir) then
    config:add_type_defs(dir)
  end

  local conf = MODS[name] or EMPTY

  for _, ign in ipairs(conf.ignore or EMPTY) do
    config:add_ignore(ign)
  end

  for _, defs in ipairs(conf.type_defs or EMPTY) do
    config:add_type_defs(defs)
  end

  for _, inc in ipairs(conf.include or EMPTY) do
    add_mod(inc, config, seen)
  end
end


---@param mod string
---@param config my.lua_ls.Config
function _M.on_lua_module(mod, config)
  add_mod(mod, config)
end


---@param types string[]
---@param config my.lua_ls.Config
function _M.on_missing_types(types, config)
  local found = luamod.find_type_defs(types)

  for _, path in ipairs(found) do
    config:add_workspace_library(path)
  end
end


---@param ws my.workspace
---@param config my.lua_ls.Config
function _M.on_workspace(ws, config)
  local dir = ws.dir
  local basename = ws.basename
  local lower = dir:lower()

  -- detect busted projects
  if fs.file_exists(dir .. ".busted") then
    add_mod("busted", config)
  end

  -- ~/git/flrgh/.dotfiles
  if dir == user_const.dotfiles.root then
    add_mod("vim", config)
    config:add_runtime_dir(user_const.dotfiles.config_nvim_lua)
    --config:add_workspace_library(user_const.dotfiles.config_nvim_lua)
    config:set_root_dir(user_const.dotfiles.config_nvim)

    for _, plugin_name in ipairs(PLUGINS) do
      local plug = plugin.get(plugin_name)
      if plug and plug.dir and plug.dir ~= "" then
        add_lib(plug.dir .. "/lua", config)
      end
    end

    if fs.dir_exists(user_const.nvim.bundle.lua) then
      config:add_runtime_dir(user_const.nvim.bundle.lua)
    else
      for _, plug in ipairs(plugin.list()) do
        local lua = plug.dir .. "/lua"
        if fs.dir_exists(lua) then
          config:add_runtime_dir(lua)
        end
      end
    end
  end

  if contains(lower, "vim")
    or contains(lower, "nvim")
    or contains(lower, "neovim")
  then
    add_mod("vim", config)
  end

  if contains(lower, "resty")
    or contains(lower, "ngx")
    or contains(lower, "nginx")
  then
    add_mod("resty", config)
  end

  -- ~/git/kong/{kong,kong-ee}
  if (basename == "kong" or basename == "kong-ee")
    and dir:find(user_const.git_root .. "/kong")
  then
    add_mod("kong", config)
  end

  if basename == "blj" then
    add_lib(dir .. "/lua", config)
  end

  do
    local res = vim.system({ "luarocks", "config", "deploy_lua_dir" },
                           { text = true }
                          ):wait()

    local stdout = res and res.stdout and #res.stdout > 0 and res.stdout
    if stdout then
      stdout = vim.trim(stdout)
      add_lib(stdout, config)
    end
  end
end


return _M
