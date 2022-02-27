--- filesystem utility functions
---@module 'local.fs'
local _M = {
  _VERSION = '0.1'
}

local expand = vim.fn.expand
local getcwd = vim.fn.getcwd
local json_decode = vim.json.decode
local fs_stat = vim.loop.fs_stat
local fs_open = vim.loop.fs_open
local fs_fstat = vim.loop.fs_fstat
local fs_read = vim.loop.fs_read
local fs_close = vim.loop.fs_close

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
---@param  fname   string
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

return _M
