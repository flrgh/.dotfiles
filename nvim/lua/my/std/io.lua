---@class my.std.io: iolib
local _M = setmetatable({}, { __index = _G.io })

local function noop_print() end
local function noop_io_write() return true end

local GLOBAL_PRINT = _G.print
local VIM_PRINT = vim.print
local VIM_NOTIFY = vim.notify
local IO_WRITE = io.write


function _M.pause(force)
  if force or _G.print == GLOBAL_PRINT then
    _G.print = noop_print
  end

  if force or vim.print == VIM_PRINT then
    vim.print = noop_print
  end

  if force or vim.notify == VIM_NOTIFY then
    vim.notify = noop_print
  end

  if force or io.write == IO_WRITE then
    io.write = noop_io_write
  end
end


function _M.unpause(force)
  if force or _G.print == noop_print then
    _G.print = GLOBAL_PRINT
  end

  if force or vim.print == noop_print then
    vim.print = VIM_PRINT
  end

  if force or vim.notify == noop_print then
    vim.notify = VIM_NOTIFY
  end

  if force or io.write == noop_io_write then
    io.write = IO_WRITE
  end
end


return _M
