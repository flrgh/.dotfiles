--- helpers for recording event/task duration
local _M = {}

local vim = vim
local WARN = vim.log.levels.WARN
local DEBUG = vim.log.levels.DEBUG
local hrtime = vim.uv.hrtime
local huge = math.huge
local fmt = string.format

local const = require "my.constants"

local function log_duration(task, duration, lvl)
  if vim.in_fast_event() then
    vim.schedule(function() log_duration(task, duration) end)
    return
  end

  lvl = lvl
     or (const.debug and WARN)
     or DEBUG

  vim.notify(fmt("task %q completed in %.3f ms", task, duration),
             lvl)
end

---@return integer time # ms
local function get_time()
  return hrtime() / 1000 / 1000
end

---@type table<string, number>
local tasks = {}

---@param task string
function _M.start(task)
  if tasks[task] then
    vim.notify("duplicate stopwatch task: " .. task, WARN)
  end

  tasks[task] = get_time()
end

---@param task string
---@return integer elapsed
function _M.finish(task)
  local started = tasks[task]
  tasks[task] = nil

  if not started then
    vim.notify("unknown stopwatch task: " .. task, WARN)
    return -huge
  end

  return get_time() - started
end

---@param task string
---@return integer elapsed
function _M.elapsed(task)
  local started = tasks[task]

  if not started then
    vim.notify("unknown stopwatch task: " .. task, WARN)
    return -huge
  end

  return get_time() - started
end

---@alias my.utils.stopwatch fun():number

---@param task string
---@param slow_if? number
---@return my.utils.stopwatch
function _M.new(task, slow_if)
  slow_if = slow_if or 1000
  local start = 0

  ---@type my.utils.stopwatch
  local function get_elapsed()
    local elapsed = get_time() - start

    if elapsed >= slow_if then
      log_duration(task, elapsed, WARN)

    else
      log_duration(task, elapsed, DEBUG)
    end

    return elapsed
  end

  start = get_time()

  return get_elapsed
end

return _M
