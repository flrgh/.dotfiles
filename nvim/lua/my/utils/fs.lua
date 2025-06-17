--- filesystem utility functions
---@module "my.utils.fs"
local _M = {}

local vim = vim
local fn = vim.fn
local loop = vim.uv
local json_decode = vim.json.decode
local fs_stat = loop.fs_stat
local fs_open = loop.fs_open
local fs_fstat = loop.fs_fstat
local fs_read = loop.fs_read
local fs_close = loop.fs_close
local fs_realpath = loop.fs_realpath
local fs_write = loop.fs_write
local fs_rename = loop.fs_rename
local fs_lstat = loop.fs_lstat
local concat = table.concat
local assert = assert
local byte = string.byte
local gsub = string.gsub
local deepcopy = vim.deepcopy
local find = string.find
local type = type
local tostring = tostring
local tonumber = tonumber

local SLASH = byte("/")

---@param n integer
---@return integer
local function oct_to_dec(n)
  return tonumber(tostring(n), 8)
end


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
  local st = fs_stat(path)
  if not st then
    return
  end

  local ft = st.type

  if ft == "link" then
    local lst = fs_lstat(path)
    return ft, lst and lst.type
  end

  return ft
end

---@param path string
function _M.stat(path)
  local st = fs_stat(path)
  if not st then
    return
  end

  if st.type == "link" then
    return fs_lstat(path)
  end

  return st
end

--- Get the size of a file
---@param  path   string
---@return integer size
function _M.size(path)
  local st = _M.stat(path)
  return (st and st.size) or -1
end

--- Read a file's contents to a string.
---@param  fname   string
---@return string? content
---@return string? error
function _M.read_file(fname)
  local stat, data, fd, err

  fd, err = fs_open(fname, "r", oct_to_dec(666))
  if not fd then
    return nil, err or "failed opening file"
  end

  stat, err = fs_fstat(fd)
  if not stat then
    return nil, err or "failed fstat-ing file"
  end

  data, err = fs_read(fd, stat.size, 0)
  if not data then
    return nil, err or "failed reading file"
  end

  assert(fs_close(fd))

  return data
end

--- Decode the contents of a json file.
---@param  fname   string
---@return table|string|number|boolean|nil json
---@return string? error
function _M.read_json_file(fname)
  local raw, err = _M.read_file(fname)
  if not raw then
    return nil, err
  end

  return json_decode(raw)
end

---@param buf? integer
---@return string
function _M.buffer_filename(buf)
  if buf then
    return vim.api.nvim_buf_get_name(buf)
  end
  return fn.expand("%:p", true)
end

---@return string
function _M.buffer_directory()
  return fn.expand("%:p:h", true)
end

local normalize
do
  local buf = {}
  local i = 0

  local function handle_part(part)
    if part == "." or part == "" then
      return

    elseif part == ".." then
      assert(i > 1, "path out of range")

      buf[i] = nil
      i = i - 1

      return

    else
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
  normalize = _M.normalize
end

---@return string?
function _M.workspace_root()
  local dir = _M.buffer_directory() or fn.getcwd()
  if not dir then
    return
  end

  dir = normalize(dir)

  while not _M.dir_exists(dir .. "/.git") do
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
  return fs_realpath(path) or _M.normalize(path)
end

---@param path string
---@return string
function _M.basename(path)
  return (normalize(path):gsub("^.*/+", ""))
end


---@param path string
---@return string
function _M.dirname(path)
  return (normalize(path):gsub("/[^/]+$", ""))
end


---@param path string
---@param data string|string[]
---@param mode integer?
---@param flags string
---@return integer|nil written
---@return string|nil error
local function write_with_flags(path, data, mode, flags)
  mode = mode or oct_to_dec(640)

  local fd, err = fs_open(path, flags, mode)
  if not fd then
    return nil, err
  end

  local typ = type(data)
  assert(typ == "string" or typ == "table",
         "invalid data type, expected a string or table "
         .. "(got " .. typ .. ")")

  local bytes
  bytes, err = fs_write(fd, data)

  local ok, cerr = fs_close(fd)

  if not ok then
    return nil, cerr

  elseif not bytes then
    return nil, err
  end

  return bytes
end

--- Write data to a file
---@param path string
---@param data string|string[]
---@param mode integer?
---@return integer|nil written
---@return string|nil error
function _M.write_file(path, data, mode)
  return write_with_flags(path, data, mode, "w+")
end


--- Append data to a file
---@param path string
---@param data string|string[]
---@param mode integer?
---@return integer|nil written
---@return string|nil error
function _M.append_file(path, data, mode)
  return write_with_flags(path, data, mode, "a+")
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

do
  ---@class my.util.fs.cache.entry
  ---
  ---@field mtime { nsec: integer, sec: integer }
  ---@field inode integer
  ---@field content any

  ---@type table<string, my.util.fs.cache.entry>
  local cache = {}

  --- This is like `read_json_file()`, but the result is cached.
  ---
  ---@param fname string
  ---@return any      content
  ---@return string?  error
  ---@return boolean? cached
  function _M.load_json_file(fname)
    fname = _M.normalize(fname)

    local st = fs_stat(fname)
    if not st then
      return nil, "could not stat() file", nil
    end

    local entry = cache[fname]
    if entry
      and entry.inode      == st.ino
      and entry.mtime.sec  == st.mtime.sec
      and entry.mtime.nsec == st.mtime.nsec
    then
      return entry.content, nil, true
    end

    local json, err = _M.read_json_file(fname)
    if err then
      return nil, err
    end

    cache[fname] = {
      content = json,
      mtime   = deepcopy(st.mtime),
      inode   = st.ino,
    }

    return json, nil, false
  end
end

---@param dir string
---@param fname string
function _M.is_child(dir, fname)
  if byte(dir, -1) == SLASH then
    dir = dir:gsub("/+$", "")
  end

  local from, to = find(fname, dir)

  return from == 1
     and byte(fname, to + 1) == SLASH
end


---@param path string
---@return string
function _M.abbreviate(path)
  if not path then return "" end
  local const = require "my.constants"

  local replace = {
    { const.nvim.runtime_lua, "{ nvim.runtime.lua }" },
    { const.nvim.plugins,     "{ nvim.plugins }" },
    { const.nvim.runtime,     "{ nvim.runtime }" },
    { const.nvim.config,      "{ nvim.userconfig }" },
    { const.workspace,        "{ workspace }" },
    { const.home,             "~" },
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


return _M
