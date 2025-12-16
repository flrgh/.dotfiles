--- Lua Module Utils.
---@class my.std.luamod
local _M = {}

local env = require("my.env")
local fs = require("my.std.fs")
local resolver = require("my.std.luamod.resolver")
local requires = require("my.std.luamod.requires")
local cmd = require("my.std.cmd")
local Set = require("my.std.set")

_M.resolver = resolver
_M.requires = requires

local pcall = pcall
local require = require
local insert = table.insert
local concat = table.concat
local gsub = string.gsub
local trim = require("my.std.string").trim

local vim = vim

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
       and dir ~= env.workspace
       and not seen[dir]
    then
      seen[dir] = dir
      insert(LUA_PATH_ENTRIES, dir)
    end
  end

  gsub(package.path, "[^;]+", add)

  local env_lua_path = os.getenv("LUA_PATH") or ""
  gsub(env_lua_path, "[^;]+", add)
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
---@return nil|string[]
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

  if dir then
    proc:cwd(dir)
  end

  local mods = Set.new()

  proc:on_stdout_line(function(line, eof)
    if eof then
      return
    end

    line = trim(line)
    if line == "" or line:sub(-1) == "." then
      return
    end

    mods:add(line)
  end)

  if cb then
    vim.defer_fn(function()
      proc:run():wait()
      cb(mods:take())
    end, 0)
  else
    proc:run():wait()
    return mods:take()
  end
end


---@param buf integer
---@return string[]
function _M.get_module_requires(buf)
  return require("my.std.luamod.requires").get_module_requires(buf)
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

    if not line:find([["match"]], nil, true) then
      return
    end

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

    ty = trim(ty)

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
