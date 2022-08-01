--- filesystem utility functions
---@module 'local.fs'
local _M = {
  _VERSION = '0.1'
}

local vim = vim
local fn = vim.fn
local loop = vim.loop
local expand = fn.expand
local getcwd = fn.getcwd
local json_decode = vim.json.decode
local fs_stat = loop.fs_stat
local fs_open = loop.fs_open
local fs_fstat = loop.fs_fstat
local fs_read = loop.fs_read
local fs_close = loop.fs_close
local fs_realpath = loop.fs_realpath
local concat = table.concat
local assert = assert
local byte = string.byte


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
  return st and st.type
end


--- Read a file's contents to a string.
---@param  fname   string
---@return string? content
---@return string? error
function _M.read_file(fname)
  local stat, data, fd, err

  fd, err = fs_open(fname, "r", 438)
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
---@return any?    json
---@return string? error
function _M.read_json_file(fname)
  local raw, err = _M.read_file(fname)
  if not raw then
    return nil, err
  end


  return json_decode(raw)
end

---@return string
function _M.buffer_filename()
  return expand("%:p", true)
end

---@return string
function _M.buffer_directory()
  return expand("%:p:h", true)
end

---@return string?
function _M.workspace_root()
  local dir = _M.buffer_directory() or getcwd()
  if not dir then
    return
  end

  while not _M.dir_exists(dir .. "/.git") do
    dir = dir:gsub("/[^/]+$", "")
    if dir == nil or dir == "/" or dir == "" then
      return
    end
  end

  return dir
end

local normalize
do
  local buf = {}
  local i = 0
  local SLASH = byte("/")
  local gsub = string.gsub

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


---@param path string
---@return string
function _M.realpath(path)
  return fs_realpath(path) or _M.normalize(path)
end

---@param path string
---@return string
function _M.basename(path)
  return (normalize(path):gsub(".*/+", ""))
end

return _M
