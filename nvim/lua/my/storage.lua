local _M = {}

local floor = math.floor
local ceil = math.ceil
local type = type

local api = vim.api

local function is_int(v)
  return type(v) == "number"
    and floor(v) == ceil(v)
end


---@class my.storage.global
---
---@field lua_lsp { [integer|string]: my.lua_ls.Config }
---
---@field [string] any
_M.global = {}


---@class my.storage.buffer
---
---@field id _vim.buffer.id
---
---@field lua_lsp my.lua_ls.Config
---@field lua_resolver my.lua.resolver
---
---@field [string] any


---@type { [_vim.buffer.id]: my.storage.buffer }
local buffers = {}

---@class my.storage.buffers : my.storage.buffer
---@field [_vim.buffer.id] my.storage.buffer
_M.buffer = {}
setmetatable(_M.buffer, {
  __index = function(_, buf)
    if buf == 0 then
      buf = api.nvim_get_current_buf()
    end

    if is_int(buf) then
      if not buffers[buf] then
        buffers[buf] = { id = buf }
      end

      return buffers[buf]
    end

    local key = buf
    buf = api.nvim_get_current_buf()

    if not buffers[buf] then
      buffers[buf] = { id = buf }
    end

    return buffers[buf][key]
  end,

  __newindex = function(_, key, value)
    local buf = api.nvim_get_current_buf()
    if not buffers[buf] then
      buffers[buf] = { id = buf }
    end
    buffers[buf][key] = value
  end,
})

local event = require("my.event")
local DEBUG = vim.log.levels.DEBUG
event.on(event.BufDelete)
  :group("storage-delete-buffer", true)
  :desc("delete buffer-local storage")
  :callback(function(e)
    vim.notify("clearing buffer-local storage for buffer: " .. tostring(e.buf), DEBUG)
    rawset(buffers, e.buf, nil)
  end)


return _M
