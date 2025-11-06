--- Lua Module Utils.
local _M = {}

local const = require("my.constants")
local fs = require("my.utils.fs")
local resolver = require("my.utils.luamod.resolver")
local requires = require("my.utils.luamod.requires")
local buffer = require("string.buffer")
local cmd = require("my.utils.cmd")
local plugin = require("my.utils.plugin")

_M.resolver = resolver
_M.requires = requires

local pcall = pcall
local require = require
local insert = table.insert
local concat = table.concat
local gsub = string.gsub
local find = string.find
local sub = string.sub
local byte = string.byte
local trim = vim.trim

local vim = vim

local LF = "\n"

local function noop() end

---@type fun(string):string[]
local split_lines
do
  local buf = {}
  local n

  local function add_line(line)
    n = n + 1
    buf[n] = line
  end

  function split_lines(s, skip_empty)
    n = 0
    gsub(s, "[^\r\n]+", add_line)

    local ret = {}
    local o = 0
    for i = 1, n do
      local line = buf[i]
      buf[i] = nil

      if not skip_empty or #line ~= 0 then
        o = o + 1
        ret[o] = line
      end
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


---@param names string[]
---@param extra_paths string[]
---@return string[]
function _M.find_type_defs(names, extra_paths)
  local namepat = "(" .. concat(names, "|") .. ")"
  local args = {
    "--one-file-system",
    "--files-with-matches",
    "-g", "*.lua",
    "-e", "---\\s*@(alias|enum|class)\\s*" .. namepat .. "(\\s+|$)",
  }

  if extra_paths then
    for _, path in ipairs(extra_paths) do
      insert(args, path)
    end
  end

  for _, lib in ipairs(LUA_PATH_ENTRIES) do
    insert(args, lib)
  end

  local proc = cmd.new("rg"):args(args)

  local found = {}
  proc:on_stdout_line(function(line, eof)
    if eof then return end
    table.insert(found, line)
  end, true)

  local res = assert(proc:run():wait())
  -- ripgrep returns 1 if no results found
  if res.code ~= 0 and res.code ~= 1 then
    vim.notify(string.format("command %s returned %s, stdout: %s, stderr: %s",
                             proc.label, res.code, res.stdout or "", res.stderr or ""))
  end

  return found
end


---@param dir? string
---@param cb? function
function _M.find_all_requires(dir, cb)
  local proc = cmd.new("rg"):args({
    "--one-file-system",
    "--glob", '*.lua',
    "--no-line-number",
    "--no-filename",
    "--line-buffered",
    "--trim",
    "--only-matching",
    "-e", [=[.*\brequire[\s\(]*["']([a-zA-Z0-9_./-]+)["'].*]=],
    "--replace", "$1",
  })

  local mods = {}
  local seen = {}
  proc:on_stdout_line(function(line, eof)
    if eof then
      if cb then
        cb(mods)
      end
      return
    end

    line = trim(line)
    if not seen[line] then
      seen[line] = true
      table.insert(mods, line)
    end
  end)

  proc:run()

  if not cb then
    proc:wait()
    return mods
  end
end


---@param buf integer
---@return string[]
function _M.get_module_requires(buf)
  return require("my.utils.luamod.requires").get_module_requires(buf)
end

---@class my.luamod.typedef
---
---@field name string
---@field label string
---@field source string
---@field mod string|nil
---@field lines string
---@field offset integer
---@field line_number integer
---@field tree string

---@param paths string[]
---@return my.luamod.typedef[]
function _M.find_all_types(paths)
  local proc = cmd.new("rg")
    :args({
      "--json",
      "--one-file-system",
      "-g", "*.lua",
      "-e", "\\s*---\\s*(?:\\(exact|private\\)\\s*)?@(?<LABEL>alias|enum|class)\\s*(?<NAME>[^\\s]+)(\\s+.*)?"
    })

  paths = paths or { assert(vim.uv.cwd()) }
  local seen = {}
  for _, extra in ipairs(paths) do
    if seen[extra] then
      error("duplicate path: " .. extra, 2)
    end
    seen[extra] = true
    proc:arg(extra)
  end

  for _, lib in ipairs(LUA_PATH_ENTRIES) do
    if not seen[lib] then
      seen[lib] = true
      table.insert(paths, lib)
      proc:arg(lib)
    end
  end

  local decode = vim.json.decode

  ---@type my.luamod.typedef[]
  local types = {}
  local n = 0

  proc:on_stdout_line(function(line, eof)
    if eof then return end

    local json = decode(line)
    if json.type ~= "match" then
      return
    end

    local data = json.data
    local fname = data.path.text
    if not fname then return end

    local text = data.submatches
    and data.submatches[1]
    and data.submatches[1].match
    and data.submatches[1].match.text
    or data.lines.text

    if not text then return end

    local label, mod, ty
    label, mod, ty = text:match("@(%w+)%s+%(([%w,]+)%)%s+([^%s]+)")

    if not label then
      label, ty = text:match("@(%w+)%s+([^%s]+)")
    end

    if not ty then return end

    ty = vim.trim(ty)

    if ty:sub(-1) == ":" then
      ty = ty:sub(1, -2)
    end

    -- ehhh just special case this for now
    if ty:find("table<K,", nil, true) then
      ty = "table<K, V>"
    end

    -- generics
    if ty:find("<", nil, true) then
      ty = ty:match("([^<]+)<[^>]+>$") or ty
    end

    if ty == "" then
      return
    end

    if not ty:find("^[a-zA-Z0-9%._:%*-]+$") then
      vim.notify("weird type name: '" .. ty .. "' in " .. fname)
    end

    local tree
    for i = 1, #paths do
      local path = paths[i]
      if fname:find(path, nil, true) == 1 then
        tree = path
        break
      end
    end

    assert(tree, "failed to find tree for " .. fname)

    n = n + 1
    types[n] = {
      name = ty,
      label = label,
      source = fname,
      tree = tree,
      mod = mod,
      lines = data.lines.text,
      offset = data.absolute_offset,
      line_number = data.line_number,
    }
  end, true)

  proc:run():wait()

  return types
end

return _M
