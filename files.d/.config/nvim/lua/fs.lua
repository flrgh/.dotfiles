local _M = {
    _VERSION = '0.1'
}

--- Check if a file exists.
-- @tparam fname string
-- @treturn exists boolean
function _M.file_exists(fname)
    local f = io.open(fname, 'rb')
    if f then f:close() end
    return f ~= nil
end

--- Read a file's contents to a string.
-- @tparam fname string
-- @treturn content string
-- @treturn err string
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
-- @tparam fname string
-- @return json
-- @treturn err string
function _M.read_json_file(fname)
    local raw, err = _M.read_file(fname)
    if not raw then
        return nil, err
    end

    return vim.fn.json_decode(raw)
end

return _M
