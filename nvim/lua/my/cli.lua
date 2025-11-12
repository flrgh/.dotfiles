local _M = {}

local table = require("my.std.table")
local string = require("my.std.string")

local byte = string.byte
local sub = string.sub
local find = string.find

local ARGS_END = "--"

local HYPHEN = byte("-")
local EQ = byte("=")
local B_A = byte("A")
local B_Z = byte("Z")
local B_a = byte("a")
local B_z = byte("z")

---@return my.cli.args.iter
function new_iter(argv, argc)
  assert(type(argv) == "table")
  assert(type(argc) == "number")

  ---@class my.cli.args.iter
  local iter = {
    pos = 0,
    len = argc or #argv,
    elems = argv,
  }

  ---@return boolean
  function iter:empty()
    return self.pos >= self.len
  end

  function iter:skip()
    assert(not self:empty())
    local n = self.pos + 1
    self.pos = n
  end

  ---@return string|nil
  function iter:next()
    if self:empty() then
      return
    end

    local n = self.pos + 1
    self.pos = n
    return assert(self.elems[n])
  end

  ---@return string|nil
  function iter:peek()
    if self:empty() then
      return
    end
    return assert(self.elems[self.pos + 1])
  end

  return iter
end

---@param b integer
---@return boolean
local function is_ascii_char(c)
  return c and (
    (c >= B_A and c <= B_Z)
    or
    (c >= B_a and c <= B_z)
  )
end

---@param input string
---@return boolean
local function parse_opt_end(input)
  return input == ARGS_END
end

---@param input string
---@return string? opt
---@return string? arg
local function parse_long(input)
  local a, b, c = byte(input, 1, 3)
  if a == HYPHEN and
    b == HYPHEN and
    is_ascii_char(c)
  then
    local opt, arg

    local from, to = find(input, "=", 4, true)
    if from then
      opt = sub(input, 3, from - 1)
      arg = sub(input, from + 1)
    else
      opt = sub(input, 3)
    end

    return opt, arg
  end
end

---@param input string
---@return "opt"|"flags"|nil
---@return string|string[]|nil
---@return string|nil
local function parse_short(input)
  local a, b, c = byte(input, 1, 3)
  if a == HYPHEN and is_ascii_char(b) then
    -- -a=<value>
    if c == EQ then
      local opt = sub(input, 2)
      input = sub(input, 4)
      return "opt", opt, input

    -- -a
    -- -abc
    else
      local flags = {}

      for i = 2, #input do
        flags[i - 1] = sub(input, i, i)
      end

      return "flags", flags
    end
  end
end

---@type string[]
_M.ARGV = nil

---@type string
_M.ARGV_0 = nil

---@type string[]
_M.ARGS = nil

---@type integer
_M.ARGC = nil

local function init_args(args)
  if _M.ARGV and not args then
    return
  end

  _M.ARGV = table.clone(args or _G.arg)
  _M.ARGV_0 = _M.ARGV[0]

  _M.ARGC = #_M.ARGV
  _M.ARGS = table.new(_M.ARGC, 0)

  for i = 1, _M.ARGC do
    _M.ARGS[i] = _M.ARGV[i]
  end
end

---@alias my.cli.argspec
---| my.cli.argspec.flag
---| my.cli.argspec.option
---| my.cli.argspec.param

---@class my.cli.argspec.flag
---@field flag string
---@field shortname? string

---@class my.cli.argspec.option
---@field option string
---@field shortname? string

---@class my.cli.argspec.param
---@field param string
---@field nargs? integer|"?"|"*"|"+"

---@class my.cli.args
---@field flags table<string, boolean>
---@field options table<string, any[]>
---@field params string[]
---@field extra? string[]

---@param spec my.cli.argspec[]
---@return spec my.cli.parser
local function new_parser(spec)
  local flags = {}
  local options = {}
  ---@type my.cli.argspec.param[]
  local params = {}
  local have_varargs = false

  for i = 1, #spec do
    local elem = spec[i]

    if elem.flag then
      assert(type(elem.flag) == "string")
      assert(elem.shortname == nil or type(elem.shortname) == "string")

      assert(flags[elem.flag] == nil)
      flags[elem.flag] = elem.flag

      if elem.shortname then
        assert(flags[elem.shortname] == nil)
        flags[elem.shortname] = elem.flag
      end

    elseif elem.option then
      assert(type(elem.option) == "string")
      assert(elem.shortname == nil or type(elem.shortname) == "string")

      assert(options[elem.option] == nil)
      options[elem.option] = elem.option

      if elem.shortname then
        assert(options[elem.shortname] == nil)
        options[elem.shortname] = elem.option
      end

    elseif elem.param then
      assert(type(elem.param) == "string")
      if elem.nargs == nil then
        elem.nargs = 1
      end

      assert((type(elem.nargs) == "number" and elem.nargs > 0)
        or (elem.nargs == "?" or elem.nargs == "*" or elem.nargs == "+"))

      if type(elem.nargs) == "string" then
        assert(not have_varargs)
        have_varargs = true
      end

      table.insert(params, elem)

    else
      error("unknown arg type")
    end
  end

  ---@type my.cli.args
  local parsed = {
    flags = table.new(0, #flags),
    options = table.new(0, #options),
    params = table.new(0, #params),
    extra = nil,
  }

  ---@class my.cli.parser
  local parser = {
    flags = flags,
    options = options,
    params = params,
    parsed = parsed,
    ---@type my.cli.args.iter
    iter = nil,

    ---@type string?
    err = nil,
    ---@type string?
    elem = nil,
  }

  ---@param elem string
  ---@param error string
  ---@return false
  function parser:error(elem, err)
    self.elem = elem
    self.err = err
    return false
  end

  ---@param elem string
  ---@param opt string
  ---@param arg? string
  ---@return boolean
  function parser:parse_opt(elem, opt, arg)
    local flag = self.flags[opt]
    if flag then
      if arg then
        return self:error(elem, "unexpected argument to flag")
      end

      self.parsed.flags[flag] = true

      return true
    end

    local option = self.options[opt]
    if option then
      arg = arg or self.iter:next()
      if not arg then
        return self:error(elem, "expected argument to option")
      end

      self.parsed.options[option] = self.parsed.options[option] or {}
      table.insert(self.parsed.options[option], arg)
      return true
    end

    return self:error(elem, "unknown flag/option")
  end

  ---@return boolean? parsed
  function parser:parse_long()
    local input = self.iter:peek()
    if not input then
      return false
    end

    local a, b, c = byte(input, 1, 3)
    if a == HYPHEN and
      b == HYPHEN and
      is_ascii_char(c)
    then
      self.iter:skip() -- consume

      local opt, arg

      local from, to = find(input, "=", 4, true)
      if from then
        opt = sub(input, 3, from - 1)
        arg = sub(input, from + 1)
      else
        opt = sub(input, 3)
      end

      return self:parse_opt(input, opt, arg)
    end

    return false
  end


  ---@return boolean? parsed
  function parser:parse_short()
    local input = self.iter:peek()
    if not input then
      return false
    end

    local a, b, c = byte(input, 1, 3)
    if a == HYPHEN and is_ascii_char(b) then
      self.iter:skip() -- consume

      -- -a=<value>
      if c == EQ then
        local opt = sub(input, 2)
        local arg = sub(input, 4)
        self:parse_opt(input, opt, arg)
        return self.err == nil

      -- -a
      -- -abc
      else
        for i = 2, #input do
          local flag = sub(input, i, i)

          if not self:parse_opt(input, flag, nil) then
            break
          end
        end

        return self.err == nil
      end
    end

    return false
  end

  function parser:parse_opt_end()
    local input = self.iter:peek()
    if not input then
      return false

    elseif input == "--" then
      self.iter:next()
      return true
    end

    return false
  end

  function parser:parse_params()
    for i = 1, #self.params do
      local spec = self.params[i]
      local nargs = spec.nargs

      if nargs == "?" then
        local param = self.iter:next()
        if param then
          self.parsed.params[spec.param] = param
        end

      elseif nargs == "*" then
        local values = {}
        self.parsed.params[spec.param] = {}
        while not self.iter:empty() do
          table.insert(values, assert(self.iter:next()))
        end

      elseif nargs == "+" then
        if self.iter:empty() then
          self:error(spec.param, "expected one or more arguments")
          return nil, self.err, self.elem
        end

        local values = {}
        self.parsed.params[spec.param] = {}
        while not self.iter:empty() do
          table.insert(values, assert(self.iter:next()))
        end

      elseif nargs == 1 then
        local param = self.iter:next()

        if param then
          self.parsed.params[spec.param] = param
        else
          self:error(spec.param, "missing param")
          return nil, self.err, self.elem
        end

      else
        local values = {}

        for i = 1, nargs do
          local param = self.iter:next()

          if param then
            values[i] = param
          else
            self:error(spec.param, "missing param")
            return nil, self.err, self.elem
          end
        end

        self.parsed.params[spec.param] = values
      end
    end

    if not self.iter:empty() then
      local extra = {}
      self.parsed.extra = {}
      while not self.iter:empty() do
        table.insert(self.parsed.extra, assert(self.iter:next()))
      end
    end

    return self.parsed
  end

  function parser:parse_next()
    if self:parse_opt_end() then
      return self:parse_params()
    end

    if self:parse_long() then
      return self:parse_next()

    elseif self.err then
      return nil, self.err, self.elem
    end

    if self:parse_short() then
      return self:parse_next()

    elseif self.err then
      return nil, self.err, self.elem
    end

    return self:parse_params()
  end

  ---@param args string[]
  ---@return my.cli.args? parsed
  ---@return string? error
  ---@return string? elem
  function parser:parse(args)
    self.iter = new_iter(args, #args)
    return self:parse_next()
  end

  return parser
end

---@param spec my.cli.argspec[]
---@return my.cli.args? parsed
---@return string? error
---@return string? elem
function _M.parse_args(spec)
  init_args()

  local parser = new_parser(spec)
  return parser:parse(_M.ARGS)
end


---@param args? string[]
function _M.init(args)
  init_args(args)
  require("my.env").init("script")
end

return _M
