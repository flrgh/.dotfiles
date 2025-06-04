--- Lua Module Utils.
local _M = {}

local const = require("my.constants")
local fs = require("my.utils.fs")

local pcall = pcall
local require = require
local insert = table.insert
local concat = table.concat
local gsub = string.gsub

local vim = vim

---@type fun(string):string[]
local split_lines
do
  local buf = {}
  local n

  local function add_line(line)
    n = n + 1
    buf[n] = line
  end

  function split_lines(s)
    n = 0
    gsub(s, "[^\r\n]+", add_line)

    local ret = {}
    for i = 1, n do
      ret[i] = buf[i]
      buf[i] = nil
    end

    return ret
  end
end


---@type string[]
local LUA_PATH_ENTRIES = {}
do
  local seen = {}

  local function add(path)
    local dir = path:gsub("%?%.lua$", "")
                    :gsub("%?/init%.lua$", "")
                    :gsub("%?%.ljbc$", "")
                    :gsub("%?/init.ljbc", "")

    dir = fs.normalize(dir)

    if path ~= ""
       and path ~= "/"
       and dir ~= const.workspace
       and not seen[dir]
    then
      seen[dir] = dir
      insert(LUA_PATH_ENTRIES, dir)
    end
  end

  package.path:gsub("[^;]+", add)
  local env_lua_path = os.getenv("LUA_PATH") or ""
  env_lua_path:gsub("[^;]+", add)
end
_M.LUA_PATH_ENTRIES = LUA_PATH_ENTRIES


---Forcibly reload a module
---@param name string
---@return any
function _M.reload(name)
  _G.package.loaded[name] = nil
  return require(name)
end

---Check if a module exists
---@param name string
---@return boolean
function _M.exists(name)
  local exists = pcall(require, name)
  return (exists and true) or false
end

---Run a function if a module exists.
---@param  name string
---@param  cb?  fun(mod: any)
---@return any
function _M.if_exists(name, cb)
  local exists, mod = pcall(require, name)

  if exists then
    if cb then cb(mod) end
    return mod
  end

  if mod:find(name, nil, true) and mod:find('not found', nil, true) then
    return
  else
    error("Failed loading module (" .. name .. "): " .. mod)
  end
end


function _M.resolver()
  return require("my.utils.luamod.resolver").new()
end


---@param names string[]
---@param extra_paths string[]
---@return string[]
function _M.find_type_defs(names, extra_paths)
  local namepat = "(" .. concat(names, "|") .. ")"

  local cmd = {
    "rg",
    "--one-file-system",
    "--files-with-matches",
    "-g", "*.lua",
    "-e", "@alias +" .. namepat,
    "-e", "@enum +" .. namepat,
    "-e", "@class +" .. namepat,
  }

  if extra_paths then
    for _, path in ipairs(extra_paths) do
      insert(cmd, path)
    end
  end

  for _, lib in ipairs(LUA_PATH_ENTRIES) do
    insert(cmd, lib)
  end

  local result = vim.system(cmd, { text = true }):wait()

  return split_lines(result.stdout)
end


---@param buf integer
---@return string[]
function _M.get_module_requires(buf)
  return require("my.utils.luamod.requires").get_module_requires(buf)
end


return _M
