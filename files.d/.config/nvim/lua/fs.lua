local _M = {
  _VERSION = '0.1'
}

local lfs = require 'lfs'

--- Check if a file exists.
---@param  fname   string
---@return boolean exists
function _M.file_exists(fname)
  local f = io.open(fname, 'rb')
  if f then f:close() end
  return f ~= nil
end

--- Check if a directory exists.
---@param  fname   string
---@return boolean exists
function _M.dir_exists(fname)
  return lfs.attributes(fname, 'mode') == 'directory'
end

--- Read a file's contents to a string.
---@param  fname   string
---@return string? content
---@return string? error
function _M.read_file(fname)
  local f, err = io.open(fname, 'rb')
  if not f then
    return nil, err
  end

  local content = f:read('*all')
  f:close()

  return content
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

  return vim.fn.json_decode(raw)
end

return _M
