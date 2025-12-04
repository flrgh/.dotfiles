---@class my.std.path
local _M = {}


local vim = vim
local api = vim.api
local uv = vim.uv

local expand = vim.fn.expand

local fs_stat = uv.fs_stat
local fs_realpath = uv.fs_realpath
local fs_rename = uv.fs_rename
local fs_lstat = uv.fs_lstat
local fs_mkdir = uv.fs_mkdir
local get_cwd = uv.cwd

local concat = table.concat
local assert = assert
local byte = string.byte
local gsub = string.gsub
local find = string.find
local type = type
local tonumber = tonumber
local band = bit.band
local getenv = os.getenv
local pairs = pairs
local ipairs = ipairs
local trim = require("my.std.string").trim

local EXEC_BITS = tonumber(0111, 8)
local SLASH = byte("/")
local DOT = byte(".")


---@param path string
---@return boolean
local function is_abs(path)
  return byte(path, 1, 1) == SLASH
end
_M.is_abs = is_abs

---@param path string
---@return boolean
local function is_self(path)
  local a, b = byte(path, 1, 3)
  return a == DOT and (b == SLASH or b == nil)
end
_M.is_self = is_self

---@param path string
---@return boolean
local function is_parent(path)
  local a, b, c = byte(path, 1, 3)
  return a == DOT and b == DOT and (c == SLASH or c == nil)
end
_M.is_parent = is_parent

_M.cwd = get_cwd

--- Check if a file exists.
---@param  fname   string
---@return boolean exists
function _M.file_exists(fname)
  local st = fs_stat(fname)
  return st and st.type == "file"
end

--- Check if a directory exists.
---@param  fname   string
---@return boolean exists
function _M.dir_exists(fname)
  local st = fs_stat(fname)
  return st and st.type == "directory"
end

---@param dir string
---@param mode? string|integer
---@return boolean? ok
---@return string? error
function _M.mkdir(dir, mode)
  mode = mode or tonumber(0755, 8)
  return fs_mkdir(dir, mode)
end


---@param dir string
---@param mode? string|integer
---@return boolean? ok
---@return string? error
function _M.mkdir_all(dir, mode)
  if _M.dir_exists(dir) then
    return true
  end

  dir = _M.normalize(dir)

  mode = mode or tonumber(0755, 8)

  local parent = dir:gsub("/+[^/]+$", "")
  if parent ~= "" then
    local ok, err = _M.mkdir_all(parent, mode)
    if not ok then
      return nil, err
    end
  end

  return _M.mkdir(dir, mode)
end

--- Check if a path exists.
---@param  path   string
---@return boolean exists
function _M.exists(path)
  local st = fs_stat(path)
  return st and st.type and true or false
end

---@param  path   string
---@return string? filetype
---@return string? linktype
function _M.type(path)
  local st = fs_lstat(path)
  if not st then
    return
  end

  local ft = st.type

  if ft == "link" then
    local lst = fs_stat(path)
    return ft, lst and lst.type
  end

  return ft
end

---@param path string
---@return uv.fs_stat.result|nil
function _M.stat(path)
  local st = fs_stat(path)
  return st
end

--- Get the size of a file
---@param  path   string
---@return integer size
function _M.size(path)
  local st = _M.stat(path)
  return (st and st.size) or -1
end

---@param buf? integer
---@return string
function _M.buffer_filename(buf)
  if buf then
    return api.nvim_buf_get_name(buf)
  end
  return expand("%:p", true)
end

---@return string
function _M.buffer_directory()
  return expand("%:p:h", true)
end

local _normalize
do
  local buf = {}
  local i = 0

  local function handle_part(part)
    if part == ".." then
      assert(i > 1, "path out of range")

      buf[i] = nil
      i = i - 1

    elseif part ~= "." and part ~= "" then
      i = i + 1
      buf[i] = part
    end
  end


  --- normalize a path string
  ---
  --- 1. De-dupe path separators  (/a//b => /a/b)
  --- 2. Collapse self references (/a/./b => /a/b)
  --- 3. Collapse parent references (/a/b/../b => /a/b)
  --- 4. Trim trailing separators (/a/b/ => /a/b)
  ---
  ---@param path string
  ---@return string
  function _M.normalize(path)
    if path == "" or path == "/" then
      return path
    end

    i = 0
    if byte(path, 1) == SLASH then
      i = i + 1
      buf[i] = ""
    end

    ---@diagnostic disable-next-line
    gsub(path, "[^/]+", handle_part)

    if i == 1 then
      path = buf[1]
      if path == "" then
        path = "/"
      end
    else
      path = concat(buf, "/", 1, i)
    end

    return path
  end
  _normalize = _M.normalize
end

---@return string?
function _M.workspace_root()
  local dir = _M.buffer_directory() or get_cwd()
  if not dir then
    return
  end

  dir = _normalize(dir)

  while not _M.exists(dir .. "/.git") do
    dir = dir:gsub("/[^/]+$", "")
    if dir == nil or dir == "/" or dir == "" then
      return
    end
  end

  return dir
end

---@param path string
---@return string
function _M.realpath(path)
  return fs_realpath(path) or _normalize(path)
end

---@param path string
---@return string
function _M.basename(path)
  return (_normalize(path):gsub("^.*/+", ""))
end


---@param path string
---@return string
function _M.dirname(path)
  return (_normalize(path):gsub("/[^/]+$", ""))
end

--- Rename a file
---@param from string
---@param to string
---@return boolean|nil success
---@return string|nil error
function _M.rename(from, to)
  return fs_rename(from, to)
end

---@param ... string
---@return string
function _M.join(...)
  local n = select("#", ...)
  assert(n > 1, "fs.join() requires at least 2 arguments")

  local first = select(1, ...)
  first = first:gsub("/+$", "")
  if first == "" then
    first = "/"
  end

  local parts = { first }

  for i = 1, n do
    local part = select(i, ...)
    part = part:gsub("/+$", "")
    if i > 1 then
      part = part:gsub("^/+", "")
    elseif part == "/" then
      part = ""
    end

    parts[i] = part
  end

  return concat(parts, "/")
end


---@param dir string
---@param fname string
---@return boolean
function _M.is_child(dir, fname)
  local cwd

  if is_abs(dir) then
    dir = _normalize(dir)
  else
    cwd = cwd or (get_cwd() .. "/")
    dir = cwd .. _normalize(dir)
  end

  if is_abs(fname) then
    fname = _normalize(fname)
  else
    cwd = cwd or (get_cwd() .. "/")
    fname = cwd .. _normalize(fname)
  end

  if #fname <= #dir then
    return false
  end

  local from, to = find(fname, dir, nil, true)

  return from == 1
     and byte(fname, to + 1) == SLASH
end


---@param path string
---@return string
function _M.abbreviate(path)
  if not path then return "" end
  local env = require("my.env")

  local replace = {
    { env.nvim.runtime_lua, "{ nvim.runtime.lua }" },
    { env.nvim.plugins,     "{ nvim.plugins }" },
    { env.nvim.runtime,     "{ nvim.runtime }" },
    { env.nvim.config,      "{ nvim.userconfig }" },
    { env.nvim.bundle.root, "{ nvim._bundle }" },
    { env.workspace.dir,    "{ workspace }" },
    { env.home,             "~" },
  }

  for _, item in ipairs(replace) do
    local from, to = path:find(item[1], nil, true)
    if from then
      path = path:sub(1, from - 1)
          .. item[2]
          .. path:sub(to + 1)
    end
  end

  return path
end


local EXE_CACHE = require("my.std.cache").new("std.path.exe")
local MISE_SHIMS

---@param path string
---@return string|false
local function _get_exe(path)
  local st = fs_stat(path)
  if st
    and st.type == "file"
    and band(st.mode, EXEC_BITS) > 0
  then
    return path
  else
    return false
  end
end

---@param path string
---@return string|nil
local function is_exe(path)
  local res = EXE_CACHE.get(path, _get_exe)
  return res or nil
end


---@return fun():string|nil
local function iter_PATH()
  local PATH = getenv("PATH") or ""
  return PATH:gmatch("[^:]+")
end

---@param name string
---@return string|nil
local function find_exe(name)
  local cached = EXE_CACHE.get(name)
  if cached ~= nil then
    return cached or nil
  end

  if find(name, "/", nil, true) then
    if not is_abs(name) then
      return find_exe(get_cwd() .. "/" .. name)
    end
    return is_exe(name)
  end

  for dir in iter_PATH() do
    local try = dir .. "/" .. name
    if is_exe(try) then
      MISE_SHIMS = MISE_SHIMS or (require("my.env").home .. "/.local/share/mise/shims")

      if dir == MISE_SHIMS then
        local cmd = require("my.std.cmd")
        local res = cmd.new(find_exe("mise") or "mise")
          :args({ "which", name })
          :save_stdout(true)
          :run()
          :wait()

        local which = res and res.stdout and trim(res.stdout)
        if which then
          EXE_CACHE.set(name, which)
          return which
        end
      end

      EXE_CACHE.set(name, try)
      return try
    end
  end

  return is_exe(name)
end

_M.executable = find_exe

---@param path string
---@param normalize? boolean
---@return fun():string|nil
function _M.iter_parents(path, normalize)
  if normalize then
    path = _normalize(path)
  end

  local abs = is_abs(path)

  ---@type string|nil
  local chunk = path

  return function()
    if not chunk then
      return
    end

    local parent = chunk:gsub("/+[^/]*$", "")
    if parent == "" then
      chunk = nil
      if abs then
        parent = "/"
      else
        parent = nil
      end

    elseif parent == chunk then
      chunk = nil

    else
      chunk = parent
    end

    return parent
  end
end

do
  _M.cache = {}

  ---@type string[]
  local PATH

  local function split_PATH()
    local path = os.getenv("PATH") or ""
    elems = {}
    local n = 0
    for elem in path:gmatch("[^:]+") do
      n = n + 1
      elems[n] = elem
    end
    return elems
  end

  ---@type string
  local HOME

  local function get_HOME()
    return require("my.env").home
  end

  ---@type string
  local MISE_SHIMS

  local function get_MISE_SHIMS()
    HOME = HOME or get_HOME()
    return HOME .. "/.local/share/mise/shims"
  end

  local norm_cache = require("my.std.cache").new("my.std.path.norm")
  local norm_cache_get = norm_cache.get

  ---@param name string
  ---@return string
  local function cache_key(name)
    if name == "/" then
      return "/"

    elseif name == "" or name == "." or name == "./" then
      return get_cwd()
    end

    if not is_abs(name) then
      name = get_cwd() .. "/" .. name
    end

    return norm_cache_get(name, _normalize)
  end

  local rel_norm_cache = require("my.std.cache").new("my.std.path.norm.rel")
  local rel_norm_cache_get = rel_norm_cache.get

  ---@param name string
  ---@return string
  function _M.cache.normalize(name)
    if is_abs(name) then
      return norm_cache_get(name, _normalize)

    else
      return rel_norm_cache_get(name, _normalize)
    end
  end

  ---@param name string
  ---@return uv.fs_stat.result? stat
  ---@return string? error
  local function stat(name)
    local st, _, err = fs_stat(name)
    if err == "ENOENT" then
      return nil

    elseif not st then
      return nil, err
    end

    return st
  end

  local stat_cache = require("my.std.cache").new("my.std.path.stat")
  local stat_cache_get = stat_cache.get

  ---@param path string
  ---@return uv.fs_stat.result?
  ---@return string? error
  function _M.cache.stat(path)
    local key = cache_key(path)
    local st, hit, err = stat_cache_get(key, stat)
    return st, err
  end

  ---@param path string
  ---@return boolean? exists
  ---@return string? error
  function _M.cache.exists(path)
    local key = cache_key(path)
    local st, _, err = stat_cache_get(key, stat)
    if err then
      return nil, err
    end

    return st ~= nil
  end

  ---@param path string
  ---@return boolean? exists
  ---@return string? error
  function _M.cache.file_exists(path)
    local key = cache_key(path)
    local st, _, err = stat_cache_get(key, stat)
    if err then
      return nil, err
    end

    return st and st.type == "file" or false
  end

  ---@param path string
  ---@return boolean? exists
  ---@return string? error
  function _M.cache.dir_exists(path)
    local key = cache_key(path)
    local st, _, err = stat_cache_get(key, stat)
    if err then
      return nil, err
    end

    return st and st.type == "directory" or false
  end

  ---@param name string
  ---@return string|nil
  function _M.cache.type(name)
    local key = cache_key(name)
    local st, _, err = stat_cache_get(key, stat)
    if err then
      return nil, err
    end

    return st and st.type
  end

  ---@param key string
  ---@return boolean
  ---@return string? error
  local function is_exe(key)
    local st, _, err = stat_cache_get(key, stat)
    if err then
      return nil, err
    end

    return st
      and st.type == "file"
      and band(st.mode, EXEC_BITS) > 0
      or false
  end

  ---@param path string
  ---@return boolean? exists
  ---@return string? error
  function _M.cache.is_exe(path)
    local key = cache_key(path)
    return is_exe(key)
  end

  local exe_cache = require("my.std.cache").new("my.std.path.exe")

  ---@param name string
  ---@return string|nil
  local function find_exe(name)
    PATH = PATH or split_PATH()

    for i = 1, #PATH do
      local dir = PATH[i]
      local try = dir .. "/" .. name

      if is_exe(try) then
        MISE_SHIMS = MISE_SHIMS or get_MISE_SHIMS()

        if dir == MISE_SHIMS then
          local cmd = require("my.std.cmd")
          local res = cmd.new(find_exe("mise") or "mise")
            :args({ "which", name })
            :save_stdout(true)
            :run()
            :wait()

          local which = res and res.stdout and trim(res.stdout)
          if which then
            return which
          end
        end

        return try
      end
    end

    return nil
  end

  ---@param name string
  ---@return string|nil
  function _M.cache.executable(name)
    if find(name, "/", nil, true) then
      local key = cache_key(name)
      return is_exe(key) and key or nil
    end

    return (exe_cache.get(name, find_exe))
  end

  function _M.cache.clear()
    norm_cache.clear()
    rel_norm_cache.clear()
    stat_cache.clear()
    exe_cache.clear()
    PATH = nil
    HOME = nil
    MISE_SHIMS = nil
  end

  function _M.cache.stats()
    return {
      norm = norm_cache.size(),
      rel_norm = rel_norm_cache.size(),
      stat = stat_cache.size(),
      exe = exe_cache.size(),
    }
  end
end

return _M
