---@class my.std.fs: my.std.path
local _M = {}

local pathlib = require("my.std.path")
_M.path = pathlib
setmetatable(_M, { __index = _M.path })

local vim = vim
local uv = vim.uv

local json_decode = vim.json.decode

local fs_stat = uv.fs_stat
local fs_open = uv.fs_open
local fs_fstat = uv.fs_fstat
local fs_read = uv.fs_read
local fs_close = uv.fs_close
local fs_write = uv.fs_write
local fs_rename = uv.fs_rename

local assert = assert
local deepcopy = vim.deepcopy
local type = type
local tonumber = tonumber
local normalize = pathlib.normalize


--- Read a file's contents to a string.
---@param  fname   string
---@return string? content
---@return string? error
function _M.read_file(fname)
  local stat, data, fd, err

  fd, err = fs_open(fname, "r", tonumber(666, 8))
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


---@param path string
---@param data string|string[]
---@param mode integer?
---@param flags string
---@return integer|nil written
---@return string|nil error
local function write_with_flags(path, data, mode, flags)
  mode = mode or tonumber(640, 8)

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

do
  ---@class my.std.fs.cache.entry
  ---
  ---@field mtime { nsec: integer, sec: integer }
  ---@field inode integer
  ---@field content any

  ---@type table<string, my.std.fs.cache.entry>
  local cache = {}

  --- This is like `read_json_file()`, but the result is cached.
  ---
  ---@param fname string
  ---@return any      content
  ---@return string?  error
  ---@return boolean? cached
  function _M.load_json_file(fname)
    fname = normalize(fname)

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

return _M
