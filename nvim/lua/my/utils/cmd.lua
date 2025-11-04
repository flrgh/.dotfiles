local buffer = require("string.buffer")
local callable = require("my.utils.types").callable
local const = require("my.constants")

--local vim = vim
local validate = vim.validate
local system = vim.system


local setmetatable = setmetatable
local type = type
local pairs = pairs
local insert = table.insert
local find = string.find
local sub = string.sub
local pcall = pcall
local fmt = string.format
local concat = table.concat
local xpcall = xpcall

local DEFAULT_TIMEOUT = 1000 * 60 -- 60s


---@alias my.cmd._uv_sink fun(err:string?, data:string?)

---@class my.cmd.opts: vim.SystemOpts
---
---@field text nil
---@field detach nil
---
---@field on_spawn? my.cmd.on_spawn
---@field on_exit? my.cmd.on_exit
---@field on_error? my.cmd.on_error
---
---@field stdin? string|string[]|my.cmd.source

---@param e string|any
---@param ... any
---@return string
local function format_err(e, ...)
  if select("#", ...) == 0 then
    return tostring(e)

  else
    return fmt(tostring(e), ...)
  end
end

---@type fun(msg:string, ...any)
local log_error
if const.headless then
  function log_error(msg, ...)
    vim.print("ERROR: " .. format_err(msg, ...) .. "\n")
  end
else
  local lvl = vim.log.levels.ERROR
  function log_error(msg, ...)
    vim.notify(format_err(msg, ...), lvl)
  end
end

---@class my.cmd
---
---@field opts my.cmd.opts
---@field inner? vim.SystemObj
---@field result my.cmd.result
local CMD = {}
local CMD_MT = { __index = CMD }

---@class my.cmd.result: vim.SystemCompleted

---@alias my.cmd.source fun(cmd: my.cmd):string|nil

---@alias my.cmd.sink fun(data: string, eof: boolean, cmd: my.cmd)

---@alias my.cmd.sink.line fun(line: string, eof: boolean, cmd: my.cmd)

---@alias my.cmd.on_spawn fun(cmd: my.cmd)

---@alias my.cmd.on_exit fun(cmd: my.cmd, result: my.cmd.result)

---@alias my.cmd.on_error fun(cmd: my.cmd, result: my.cmd.result)


---@param cmd string[]
---@return string
local function mklabel(cmd)
  local label
  local len = #cmd
  if len == 0 then
    label = "<empty>"

  elseif len == 1 then
    label = fmt("%q", cmd[1])

  else
    label = {}
    for i = 1, len do
      label[i] = fmt("%q", cmd[i])
    end
    label = "[" .. concat(label, ", ") .. "]"
  end

  return label
end


---@param cmd my.cmd
---@param id "stdin"|"stdout"|"stderr"
local function error_handler(cmd, id)
  return function(err)
    if cmd.any_failed then
      return
    end

    log_error("cmd %s %s handler exception:\n\t%s\n%s",
              cmd.label, id, err, debug.traceback())

    cmd.any_failed = true
    cmd:kill(9)
  end
end


---@param cmd my.cmd
---@param fn function
local function wrap_pipe_writer(cmd, fn)
  local on_err = error_handler(cmd, "stdin")

  local function wrapped()
    return fn(cmd)
  end

  return function(cmd)
    if cmd.any_failed then
      return nil, true
    end

    local ok, res = xpcall(wrapped, on_err)
    if ok then
      return res

    else
      return nil, true
    end
  end
end


---@param cmd my.cmd
---@param fn function
---@param id "stdout"|"stderr"
local function wrap_pipe_reader(cmd, fn, id)
  local on_err = error_handler(cmd, id)

  return function(data, eof)
    if cmd.any_failed then
      return nil, true
    end

    local _, res = xpcall(function()
      return fn(data, eof, cmd)
    end, on_err)

    if cmd.any_failed then
      return nil, true
    end

    return res
  end
end


---@param cmd my.cmd
---@param fn my.cmd.sink
---@param id "stdout"|"stderr"
---@return function
local function new_reader(cmd, fn, id)
  return wrap_pipe_reader(cmd, function(err, data)
    if err then
      error(id .. ": " .. err)
    end

    if data and data ~= "" then
      fn(data, false, cmd)

    else
      fn(nil, true, cmd)
    end
  end, id)
end


---@param cmd my.cmd
---@param fn my.cmd.source
local function send_stdin(cmd, fn)
  local obj = cmd.inner
  repeat
    local data, err = fn(cmd)
    if err then
      return
    end
    obj:write(data)
  until not data
end


---@param cmd my.cmd
---@param on_exit? function
---@param on_error? function
local function wrap_on_exit(cmd, on_exit, on_error)
  ---@param result vim.SystemCompleted
  return function(result)
    cmd.result = result
    local state = cmd.inner._state
    if state and state.done == "timeout" then
      result.timeout = true
      result.failed = true
    end

    if result.code ~= 0 or cmd.any_failed then
      result.failed = true
    end

    if cmd.stdout then
      result.stdout = cmd.stdout
    end

    if cmd.stderr then
      result.stderr = cmd.stderr
    end

    if on_exit then
      on_exit(cmd, result)
    end

    if result.failed and on_error then
      on_error(cmd, result)
    end
  end
end


---@param cmd string
---@return my.cmd
function CMD.new(cmd)
  local self = setmetatable({
    opts = {
      cwd = nil,

      env = nil,
      clear_env = true,

      stdin = nil,
      stdout = false,
      stderr = false,

      timeout = DEFAULT_TIMEOUT,

      -- unused
      text = nil,
      detach = nil,
    },

    inner = nil,
  }, CMD_MT)

  local ty = type(cmd)
  if ty == "table" then
    validate("cmd[1]", cmd[1], "string")
    self.opts.cmd = { cmd[1] }
    for i = 2, #cmd do
      self:arg(cmd[i])
    end

  elseif ty == "string" then
    self.opts.cmd = { cmd }

  else
    error("invalid type for 'cmd': " .. ty, 2)
  end

  return self
end


---@param timeout integer
---@return my.cmd
function CMD:timeout(timeout)
  validate("timeout", timeout, "number")
  self.opts.timeout = timeout
  return self
end


---@param arg string
---@return my.cmd
function CMD:arg(arg)
  validate("arg", arg, "string")
  insert(self.opts.cmd, arg)
  return self
end


---@param arg string[]
---@return my.cmd
function CMD:args(args)
  validate("args", args, "table")
  for i = 1, #args do
    self:arg(args[i])
  end
  return self
end


---@param var string
---@param value string
---@return my.cmd
---@overload fun(self: my.cmd, vars: { [string]: string }):my.cmd
function CMD:env(var, value)
  if type(var) == "table" then
    for name, val in pairs(var) do
      self:env(name, val)
    end

    return self
  end

  validate("var", var, "string")

  local valt = type(value)
  if valt == "number" or valt == "boolean" then
    value = tostring(valt)

  elseif valt ~= nil and valt ~= "string" then
    error("env var value must be a string", 2)
  end

  self.opts.env = self.opts.env or {}
  self.opts.env[var] = value

  return self
end


---@param inherit? boolean # defaults to `true`
---@return my.cmd
function CMD:inherit_env(inherit)
  if inherit == nil then
    inherit = true

  else
    validate("inherit", inherit, "boolean")
  end

  self.opts.clear_env = not inherit

  return self
end


---@param stdin string|string[]|my.cmd.source
---@return my.cmd
function CMD:stdin(stdin)
  if callable(stdin) then
    stdin = wrap_pipe_writer(self, stdin)

  else
    local ty = type(stdin)
    if ty ~= "string" and ty ~= "table" and not callable(stdin) then
      error("'stdin' invalid type", 2)
    end
  end

  self.opts.stdin = stdin

  return self
end


---@param stdout my.cmd.sink
---@return my.cmd
function CMD:on_stdout(stdout)
  if type(stdout) ~= "function" then
    error("'stdout' invalid type", 2)
  end

  self.opts.stdout = new_reader(self, stdout, "stdout")

  return self
end

---@param id "stdout"|"stderr"
local function save_stream(id)
  local buf = buffer.new()
  return function(data, eof, cmd)
    if data then
      buf:put(data)

    else
      assert(eof)
      cmd[id] = buf:get()
    end
  end
end

---@return my.cmd
function CMD:save_stdout(save)
  if save == false then
    self.opts.stdout = nil
  else
    self:on_stdout(save_stream("stdout"))
  end

  return self
end

---@return my.cmd
function CMD:save_stderr(save)
  if save == false then
    self.opts.stderr = nil
  else
    self:on_stderr(save_stream("stderr"))
  end

  return self
end


local function line_handler(cb, skip_empty)
  ---@type string.buffer
  local buf

  return function(chunk, eof, cmd)
    if eof then
      if buf then
        if not skip_empty or #buf > 0 then
          cb(buf:get(), false, cmd)
        end
      end

      cb(nil, true, cmd)
      return
    end

    if not buf then
      buf = buffer.new()
    end

    local pre_buf_len = #buf

    if pre_buf_len == 0 then
      buf:set(chunk)
    else
      buf:put(chunk)
    end

    local chunk_offset = 1
    local chunk_len = #chunk
    local from, to = find(chunk, "\n", chunk_offset, true)
    while from do
      assert(from == to, "multi-byte newline??")

      local line

      -- on the first iteration of this loop, the line length is:
      --
      -- number of bytes previously in the buffer before we were called
      -- +
      -- the number of bytes up til the newline
      if chunk_offset == 1 then
        line = buf:get(pre_buf_len + (from - 1))

      -- on subsequent iterations of this loop, the resulting line is:
      --
      -- the number of bytes from the last newline to this one
      else
        line = buf:get(from - chunk_offset)
      end

      cb(line, false, cmd)

      -- skip over the newline
      buf:skip(1)

      chunk_offset = to + 1
      from, to = find(chunk, "\n", chunk_offset, true)
    end
  end
end

---@param fn my.cmd.sink.line
---@param skip_empty? boolean
---@return my.cmd
function CMD:on_stdout_line(fn, skip_empty)
  validate("fn", fn, callable)
  return self:on_stdout(line_handler(fn, skip_empty))
end


---@param fn my.cmd.sink.line
---@param skip_empty? boolean
---@return my.cmd
function CMD:on_stderr_line(fn, skip_empty)
  validate("fn", fn, callable)
  return self:on_stderr(line_handler(fn, skip_empty))
end


---@param fn my.cmd.sink
---@return my.cmd
function CMD:on_stderr(fn)
  validate("fn", fn, callable)
  self.opts.stderr = new_reader(self, fn, "stderr")
  return self
end


---@param cwd string
---@return my.cmd
function CMD:cwd(cwd)
  validate("cwd", cwd, "string")
  self.opts.cwd = cwd
  return self
end


---@param fn my.cmd.on_spawn
---@return my.cmd
function CMD:on_spawn(fn)
  validate("fn", fn, callable)
  self.opts.on_spawn = fn
  return self
end


---@param fn my.cmd.on_exit
---@return my.cmd
function CMD:on_exit(fn)
  validate("fn", fn, callable)
  self.opts.on_exit = fn
  return self
end


---@param fn my.cmd.on_error
---@return my.cmd
function CMD:on_error(fn)
  validate("fn", fn, callable)
  self.opts.on_error = fn
  return self
end


---@return my.cmd
function CMD:run()
  local opts = self.opts

  local cmd = opts.cmd
  opts.cmd = nil
  self.label = mklabel(cmd)

  local on_spawn = opts.on_spawn
  opts.on_spawn = nil

  local on_exit = wrap_on_exit(self, opts.on_exit, opts.on_error)
  opts.on_exit = nil
  opts.on_error = nil

  local stdin_handler = opts.stdin
  if callable(stdin_handler) then
    -- must set to `true`, else vim.system() won't open a pipe for stdin
    opts.stdin = true

  else
    stdin_handler = nil
  end


  local obj = system(cmd, opts, on_exit)
  self.inner = obj
  self.pid = obj.pid

  if on_spawn then
    on_spawn(self)
  end

  if stdin_handler then
    send_stdin(self, stdin_handler)
  end

  return self
end


---@param timeout? integer
---@return vim.SystemCompleted
function CMD:wait(timeout)
  return self.inner:wait(timeout)
end


---@param signal? string|integer
function CMD:kill(signal)
  return self.inner:kill(signal)
end


---@param data string[]|string|nil
---@return my.cmd
function CMD:write(data)
  self.inner:write(data)
end


---@return boolean
function CMD:is_closing()
  return self.inner:is_closing()
end


return {
  new = CMD.new,
}
