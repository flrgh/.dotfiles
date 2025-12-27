---@class my.state
local _M = {}

local floor = math.floor
local ceil = math.ceil
local type = type
local tostring = tostring
local tonumber = tonumber

local api = vim.api

---@param v any
---@return boolean
local function is_valid_buf_id(v)
  return type(v) == "number"
    and v > 0
    and floor(v) == ceil(v)
end

---@param v integer
---@return string
local function buf_id(v)
  assert(is_valid_buf_id(v))
  return tostring(v)
end

---@type { [string]: boolean }
local _valid_buffers = {}


---@param buf integer
---@return boolean
local function is_loaded(buf)
  local id = buf_id(buf)
  local valid = _valid_buffers[id]
  if valid ~= nil then
    return valid
  end

  return api.nvim_buf_is_valid(buf)
    and api.nvim_buf_is_loaded(buf)
end


---@class my.state.global
---
---@field lua_lsp { [integer|string]: my.lua_ls.Config }
---
---@field workspace my.workspace
---
---@field [string] any
_M.global = {}


---@class my.state.buffer
---
---@field id _vim.buffer.id
---
---@field lua_lsp my.lua_ls.Config
---@field lua_resolver my.lua.resolver
---
---@field is_loaded fun(self: my.state.buffer):boolean
---
---@field [string] any

---@param self my.state.buffer
---@return boolean
local function buf_is_loaded(self)
  return is_loaded(self.id)
end

---@param id integer
---@return my.state.buffer
local function new_buffer(id)
  assert(is_valid_buf_id(id))
  return {
    id = id,
    is_loaded = buf_is_loaded,
  }
end

---@type my.state.buffer
local unloaded_buffer = setmetatable({
  id = -1,
  is_loaded = function()
    return false
  end,
}, {
  __index = function()
    return nil
  end,
  __newindex = function()
  end,
})

---@type { [_vim.buffer.id]: my.state.buffer }
local buffers = {}

---@class my.state.buffers : my.state.buffer
---@field [_vim.buffer.id] my.state.buffer
_M.buffer = {}
setmetatable(_M.buffer, {
  __index = function(_, buf)
    if buf == nil or buf == 0 then
      buf = api.nvim_get_current_buf()
    end

    assert(buf ~= nil and buf ~= 0)

    if is_valid_buf_id(buf) then
      if not is_loaded(buf) then
        return unloaded_buffer
      end

      local obj = buffers[buf]
      if not obj then
        obj = new_buffer(buf)
        buffers[buf] = obj
      end
      return obj
    end

    local key = buf
    buf = api.nvim_get_current_buf()

    if not is_loaded(buf) then
      return nil
    end

    local obj = buffers[buf]
    if not obj then
      obj = new_buffer(buf)
      buffers[buf] = obj
    end

    return obj[key]
  end,

  __newindex = function(_, key, value)
    local buf = api.nvim_get_current_buf()
    _M.buffer[buf][key] = value
  end,
})

function _M.init_auto_commands()
  local event = require("my.event")
  local DEBUG = vim.log.levels.DEBUG

  event.on(event.BufUnload)
    :group("state-unload-buffer", true)
    :desc("remove buffer from valid buffer list")
    :callback(function(e)
      local id = buf_id(e.buf)
      _valid_buffers[id] = false
    end)

  event.on(event.BufDelete)
    :group("state-delete-buffer", true)
    :desc("delete buffer-local state")
    :callback(function(e)
      local id = buf_id(e.buf)
      _valid_buffers[id] = nil
      vim.notify("clearing buffer-local state for buffer: " .. id, DEBUG)
      rawset(buffers, e.buf, nil)
    end)

  event.on({ event.BufAdd, event.BufNew })
    :group("state-create-buffer", true)
    :desc("initialize buffer-local state")
    :callback(function(e)
      local id = buf_id(e.buf)
      _valid_buffers[id] = true
      vim.notify("declaring new buffer " .. id, DEBUG)
    end)
end

return _M
