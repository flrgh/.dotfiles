local _M = {}

local env = require("my.env")
local const = require("my.lsp.lua_ls.constants")
local std = require("my.std")
local plugins = require("my.plugins")

local luamod = std.luamod
local fs = std.fs
local contains = std.string.contains
local find = std.string.find
local sub = std.string.sub


---@type string|false
local LUAROCKS_DEPLOY_DIR
local TYPE_DIR = const.LUA_TYPE_ANNOTATIONS
local EMPTY = {}


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

    globals = {
      "after_each",
      "before_each",
      "describe",
      "expose",
      "finally",
      "insulate",
      "it",
      "lazy_setup",
      "lazy_teardown",
      "mock",
      "pending",
      "pending",
      "randomize",
      "setup",
      "spec",
      "spy",
      "strict_setup",
      "strict_teardown",
      "stub",
      "teardown",
      "test",
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
      env.nvim.runtime_lua,
    },

    ignore = {
      "lspconfig/server_configurations"
    },
    globals = {
      "vim",
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

    globals = {
      "ngx",
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

      "bazel-bin",
      "bazel-kong-ee",
      "bazel-out",
      "bazel-testlogs",

      "*/lua_resty_*",
      "*/resty/gcp",
      "*/resty/aws/raw-api",
    },

    globals = {
      "kong",
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
local function add_lib(dir, config, meta)
  if fs.dir_exists(dir) then
    config:add_library(dir, meta)
    return true
  end
  return false
end


---@param name string
---@param config my.lua_ls.Config
---@param seen? table
---@return boolean
local function add_mod(name, config, seen)
  if is_path(name) then
    return add_lib(name, config)
  end

  local dot = find(name, ".", nil, true)
  if dot and dot > 1 then
    name = sub(name, 1, dot - 1)
  end
  if name == "" then
    return false
  end

  if config.modules:contains(name) then
    return false
  end

  config.meta[name] = true
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

  for _, gl in ipairs(conf.globals or EMPTY) do
    config:add_global(gl)
  end

  for _, inc in ipairs(conf.include or EMPTY) do
    add_mod(inc, config, seen)
  end


  return true
end


---@param mod string
---@param config my.lua_ls.Config
function _M.on_lua_module(mod, config)
  add_mod(mod, config)
end


local _TYPES = {}

---@param config my.lua_ls.Config
local function find_all_types(config)
  local types = _TYPES[config.id]
  if types then
    return types
  end

  local extra_paths
  if config.meta.neovim then
    extra_paths = plugins.lua_dirs()
    table.insert(extra_paths, env.nvim.runtime)
  end

  local all = luamod.find_all_types(extra_paths)
  types = {}
  for _, def in ipairs(all) do
    types[def.name] = types[def.name] or {}
    table.insert(types[def.name], def.source)
  end

  _TYPES[config.id] = types

  return types
end


---@param types string[]
---@param config my.lua_ls.Config
function _M.on_missing_types(types, config)
  if true then return end

  config:with_mutex("hooks.on_missing_types", function()
    local all = find_all_types(config)

    local found = std.Set()
    for _, ty in ipairs(types) do
      local files = all[ty]
      if files then
        found:add_all(files)
      end
    end

    found = found:take()

    for _, path in ipairs(found) do
      config:add_workspace_library(path)
    end
  end)
end


---@param ws my.workspace
---@param config my.lua_ls.Config
function _M.on_workspace(ws, config)
  local dir = ws.dir
  local basename = ws.basename
  local lower = dir:lower()

  add_lib(dir, config, { source = SRC_WORKSPACE_ROOT })

  if basename == "doorbell"
    or basename == "doorbell-dev"
    or basename == "doorbell-ng"
  then
    add_mod("doorbell", config)
  end

  -- detect busted projects
  if fs.file_exists(dir .. "/.busted") then
    add_mod("busted", config)
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
    and dir:find(env.git_root .. "/kong")
  then
    add_mod("kong", config)
  end

  if LUAROCKS_DEPLOY_DIR == nil then
    local res = require("my.std.cmd").new("luarocks")
      :args({ "config", "deploy_lua_dir" })
      :save_stdout(true)
      :run()
      :wait()

    local stdout = res and res.stdout and std.string.trim(res.stdout)
    if stdout and stdout ~= "" then
      LUAROCKS_DEPLOY_DIR = stdout
    else
      LUAROCKS_DEPLOY_DIR = false
    end
  end

  if LUAROCKS_DEPLOY_DIR then
    config:add_runtime_dir(LUAROCKS_DEPLOY_DIR, { source = "luarocks.config.deploy_lua_dir" })
  end
end


return _M
