local _M = {}

_M.types = require("my.utils.types")
_M.string = require("my.utils.string")
_M.cmd = require("my.utils.cmd")
_M.fs = require("my.utils.fs")
_M.plugin = require("my.utils.plugin")
_M.luamod = require("my.utils.luamod")

_M.is_callable = _M.types.callable

_M.output = {}

do
  local function noop_print() end
  local function noop_io_write() return true end

  local GLOBAL_PRINT = _G.print
  local VIM_PRINT = vim.print
  local VIM_NOTIFY = vim.notify
  local IO_WRITE = io.write

  function _M.output.pause(force)
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

  function _M.output.unpause(force)
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
end

_M.table = {}
do
  local clear = require("table.clear")
  local new = require("table.new")
  local pairs = pairs
  local type = type

  _M.table.new = new
  _M.table.clear = clear

  ---@generic T : table
  ---@param src T
  ---@return T
  function _M.table.clone(src)
    if type(src) ~= "table" then
      error("input was not a table", 2)
    end

    local clone = new(#src, 0)
    for k, v in pairs(src) do
      clone[k] = v
    end

    return clone
  end
end

---@param max_timeout? integer
---@return my.util.mutex
function _M.mutex(max_timeout)
  max_timeout = max_timeout or 10000 -- 10s

  local _locked = false

  local function is_locked()
    return _locked == true
  end

  local function is_unlocked()
    return _locked == false
  end

  local wait = vim.wait
  local ceil = math.ceil

  local function acquire()
    local timeout = 10
    local interval = 1
    local waited = 0

    while is_locked() do
      wait(timeout, is_unlocked, interval)
      waited = waited + timeout
      assert(waited < max_timeout, "timed out acquiring lock")

      timeout = ceil(timeout * 1.5)
      interval = ceil(interval * 1.5)
    end

    assert(is_unlocked())
    _locked = true
  end

  local function release()
    assert(is_locked())
    _locked = false
  end

  ---@class my.util.mutex
  local mutex = {
    acquire = acquire,
    release = release,
    locked = is_locked,
    unlocked = is_unlocked,
  }

  return mutex
end

return _M
