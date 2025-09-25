local vim = vim
local api = vim.api

local startswith = vim.startswith
local endswith   = vim.endswith

local get_keymap      = api.nvim_get_keymap
local buf_get_keymap  = api.nvim_buf_get_keymap

local del_keymap      = api.nvim_del_keymap
local buf_del_keymap  = api.nvim_buf_del_keymap

local set_keymap      = api.nvim_set_keymap
local buf_set_keymap  = api.nvim_buf_set_keymap

local get_current_buf = api.nvim_get_current_buf

local fmt = string.format
local insert = table.insert

local is_callable = require("my.utils").is_callable
local clear = require("table.clear")

local _M = {}

local CR = "<CR>"
local Cmd = "<Cmd>"
local Plug = "<Plug>"

_M.CR       = CR
_M.Return   = CR
_M.Enter    = CR


_M.Delete = "<Del>"
_M.Del    = _M.Delete
_M.End    = "<End>"
_M.Escape = "<Esc>"
_M.Esc    = _M.Escape
_M.Help   = "<Help>"
_M.Home   = "<Home>"
_M.Insert = "<Insert>"
_M.Undo   = "<Undo>"

_M.NOP      = "<NOP>"
_M.EOL      = "<EOL>"

_M.F1       = "<F1>"
_M.F2       = "<F2>"
_M.F3       = "<F3>"
_M.F4       = "<F4>"
_M.F5       = "<F5>"
_M.F6       = "<F6>"
_M.F7       = "<F7>"
_M.F8       = "<F8>"
_M.F9       = "<F9>"
_M.F10      = "<F10>"
_M.F11      = "<F11>"
_M.F12      = "<F12>"

_M.PageUp   = "<PageUp>"
_M.PageDown = "<PageDown>"

_M.Tab      = "<Tab>"
_M.Space    = "<Space>"

_M.Up       = "<Up>"
_M.Down     = "<Down>"
_M.Left     = "<Left>"
_M.Right    = "<Right>"

_M.Dot      = "."
_M.Period   = _M.Dot

local alias
do

  ---@type table<string, string>
  local wrapped = {
    Enter       = _M.Enter,
    Return      = _M.Return,

    Delete = _M.Delete,
    End    = _M.End,
    Escape = _M.Escape,
    Help   = _M.Help,
    Home   = _M.Home,
    Insert = _M.Insert,
    Undo   = _M.Undo,

    F1  = _M.F1,
    F2  = _M.F2,
    F3  = _M.F3,
    F4  = _M.F4,
    F5  = _M.F5,
    F6  = _M.F6,
    F7  = _M.F7,
    F8  = _M.F8,
    F9  = _M.F9,
    F10 = _M.F10,
    F11 = _M.F11,
    F12 = _M.F12,

    PageUp   = _M.PageUp,
    PageDown = _M.PageDown,

    Tab   = _M.Tab,
    Space = _M.Space,

    Up    = _M.Up,
    Down  = _M.Down,
    Left  = _M.Left,
    Right = _M.Right,

    Dot    = _M.Dot,
    Period = _M.Period,
  }


  ---@type table<string, string>
  local unwrapped = {}

  for name, value in pairs(wrapped) do
    unwrapped[name] = value:gsub("^<(.*)>$", "%1")
  end

  ---@param key string|integer
  ---@param wrap? boolean
  ---@return string
  function alias(key, wrap)
    local lookup = wrap and wrapped or unwrapped
    return lookup[key] or key
  end
end


---@class my.keymap.tagged.entry
---
---@field mode string
---@field lhs string
---@field buf? number
---@field old? vim.api.keyset.get_keymap[]

---@class my.keymap.binding.opts: vim.api.keyset.keymap
---
---@field mode string
---@field lhs string
---@field rhs string|function|table
---@field tag? string
---@field buffer? boolean|integer
---@field no_auto_cr? boolean

---@type { [string]: my.keymap.tagged.entry[] }
local TAGS = {}


---@param a table
---@param b table
---@return table
local function extend(a, b)
  if not a then
    return b
  elseif not b then
    return a
  end

  return vim.tbl_deep_extend("force", a, b)
end


---@param mode string
---@param lhs string
---@param tag string
---@param buf? integer
local function save_tagged(mode, lhs, tag, buf)
  if not tag then
    return
  end

  TAGS[tag] = TAGS[tag] or {}
  insert(TAGS[tag], {
    mode = mode,
    lhs = lhs,
    buf = buf,
  })
end

---@type vim.api.keyset.keymap
local KOPTS = {}

---@param kopts vim.api.keyset.keymap
---@param opts my.keymap.binding.opts
local function setopts(kopts, opts)
  kopts.callback         = opts.callback
  kopts.desc             = opts.desc
  kopts.expr             = opts.expr
  kopts.noremap          = opts.noremap
  kopts.nowait           = opts.nowait
  kopts.replace_keycodes = opts.replace_keycodes
  kopts.script           = opts.script
  kopts.silent           = opts.silent
  kopts.unique           = opts.unique
end

---@param opts my.keymap.binding.opts
---@param extra my.keymap.binding.opts
local function extend_user_opts(opts, extra)
  setopts(opts, extra)
  opts.mode       = extra.mode
  opts.lhs        = extra.lhs
  opts.rhs        = extra.rhs
  opts.tag        = extra.tag
  opts.buffer     = extra.buffer
  opts.no_auto_cr = extra.no_auto_cr
end

---@param mode string
---@param key string
---@param action string
---@param opts? my.keymap.binding.opts
local function create_keymap(opts)
  --vim.notify(vim.inspect(opts))
  local callback, rhs
  if is_callable(opts.rhs) then
    callback = opts.rhs
    rhs = ""
  else
    callback = nil
    rhs = opts.rhs
  end

  local buf = opts.buffer
  if buf == true or buf == 0 then
    buf = get_current_buf()
  elseif buf == false then
    buf = nil
  end

  setopts(KOPTS, opts)
  KOPTS.callback = callback

  save_tagged(opts.mode, opts.lhs, opts.lhs, buf)

  if buf then
    return buf_set_keymap(buf, opts.mode, opts.lhs, rhs, KOPTS)
  else
    return set_keymap(opts.mode, opts.lhs, rhs, KOPTS)
  end
end

---@class my.key.binding
local binding = {
  ---@type my.keymap.binding.opts
  opts = {},
  ---@type boolean|nil
  started = false,
}

---@param mode_or_opts string|my.keymap.binding.opts
---@param keys string
---@return my.key.binding
function binding.new(mode_or_opts, keys)
  local self = binding
  assert(not self.started, "overwriting previous key binding")

  if type(mode_or_opts) == "table" then
    local opts = mode_or_opts
    assert(type(opts.mode) == "string")
    extend_user_opts(self.opts, opts)
  else
    local mode = mode_or_opts
    assert(type(mode) == "string")
    self.opts.mode = mode
  end

  assert(type(keys) == "string")

  self.opts.lhs = keys
  self.started = true
  return self
end


---@param desc string
---@return my.key.binding
function binding:desc(desc)
  assert(type(desc) == "string")
  assert(self == binding and self.started)
  self.opts.desc = desc
  return self
end

---@param tag string
---@return my.key.binding
function binding:tag(tag)
  assert(type(tag) == "string")
  assert(self == binding and self.started)
  self.opts.tag = tag
  return self
end

---@param buffer string
---@return my.key.binding
function binding:buffer(buffer)
  assert(self == binding and self.started)
  assert(type(buffer) == "number" or type(buffer) == "boolean")
  if buffer == false then
    buffer = nil
  end
  self.opts.buffer = buffer
  return self
end

---@param silent boolean
---@return my.key.binding
function binding:silent(silent)
  assert(type(silent) == "boolean")
  assert(self == binding and self.started)
  self.opts.silent = silent
  return self
end

---@param recursive boolean
---@return my.key.binding
function binding:recursive(recursive)
  assert(type(recursive) == "boolean")
  assert(self == binding and self.started)
  self.opts.noremap = not recursive
  return self
end

---@param self my.key.binding
local function _create_binding(self)
  assert(self == binding
         and self.started
         and self.opts.lhs
         and self.opts.rhs)

  create_keymap(self.opts)
  clear(self.opts)
  self.started = false
end

---@param callback function|table
function binding:callback(callback)
  assert(is_callable(callback))
  assert(self.opts.rhs == nil)
  self.opts.rhs = callback
  return _create_binding(self)
end

---@param raw string
function binding:raw(raw)
  assert(type(raw) == "string")
  assert(self.opts.rhs == nil)
  self.opts.rhs = raw
  return _create_binding(self)
end

---@param cmd string
function binding:cmd(cmd)
  return self:raw(Cmd .. cmd .. CR)
end

---@param plugin string
function binding:plugin(plugin)
  return self:raw(Plug .. "(" .. plugin .. ")")
end

---@param action string|function|table
function binding:action(action)
  if is_callable(action) then
    return self:callback(action)
  elseif action == nil then
    vim.notify(fmt("empty %q mode key binding for %q", self.opts.mode, self.opts.lhs),
               vim.log.levels.WARN)
  else
    return self:raw(action)
  end
end

_M.normal = {}

---@param keys string
---@return my.key.binding
function _M.normal.on(keys)
  return binding.new("n", keys)
end

_M.on = _M.normal.on



local map_mt = {
  ---@param self my.keymap.binding
  ---@param key string
  ---@param v   my.keymap.action|nil
  __newindex = function(self, key, v)
    ---@type my.keymap.binding.opts
    local opts

    if type(v) == "string" or is_callable(v) then
      opts = { lhs = key, rhs = v }

    elseif type(v) == "table" then
      opts = vim.deepcopy(v)

      opts.lhs = key

      opts.rhs = opts[1] or opts.rhs
      opts[1] = nil

      opts.desc = opts[2] or opts.desc
      opts[2] = nil

      opts.tag = opts[3] or opts.tag
      opts[3] = nil
    end

    if opts == nil then
      vim.notify(fmt("invalid %q mode key binding: %q", self.opts.mode, key),
                 vim.log.levels.WARN)

      return

    elseif opts.rhs == nil then
      vim.notify(fmt("empty %q mode key binding: %q", self.opts.mode, opts.lhs),
                 vim.log.levels.DEBUG)
      return
    end

    if type(opts.rhs) == "string" and not opts.no_auto_cr then
      -- auto-append Enter/<CR> to commands
      if startswith(opts.rhs, ':') then
        if not endswith(opts.rhs:upper(), CR) then
          opts.rhs = opts.rhs .. CR
        end
      end
    end

    opts = extend(self.opts, opts)
    return create_keymap(opts)
  end,

  ---@param self my.keymap.binding
  ---@param key string
  ---@return my.key.binding
  ---@overload fun(key: { [string]: my.keymap.action.table }, opts: my.keymap.binding.opts|nil)
  __call = function(self, key, opts)
    if type(key) ~= "table" then
      return binding.new(self.opts, key)
    end

    opts = vim.tbl_extend("keep", opts or {}, self.opts)
    for k, v in pairs(key) do
      opts.lhs = k
      opts.rhs = nil
      opts.desc = nil

      if type(v) == "table" and not is_callable(v) then
        opts.rhs = v[1] or v.rhs
        opts.desc = v[2] or v.desc
      else
        opts.rhs = v
      end


      if opts.rhs then
        create_keymap(opts)
      else
        vim.notify(fmt("empty %q mode binding for %q", opts.mode, opts.lhs),
                   vim.log.levels.WARN)
      end
    end
  end,
}


---@alias my.keymap.mode "n"|"v"|"x"|"i"|"o"|""

---@class my.keymap.action.table : my.keymap.binding.opts
---@field [1] string|function # the RHS of the key map
---@field [2] string|nil      # shorthand for desc = ...
---@field [3] string|nil      # shorthand for tag = ...

---@alias my.keymap.action string|my.keymap.action.table

---@class my.keymap.binding
---
---@field opts my.keymap.binding.opts
---@field [string] my.keymap.action
---
---@overload fun(self: my.keymap.binding, key: string):my.key.binding
---@overload fun(self: my.keymap.binding, key: { [string]: my.keymap.action.table }, opts: my.keymap.binding.opts|nil)
---@operator call:my.key.binding


---@param opts my.keymap.binding.opts
---@return my.keymap.binding
local function make_map(opts)
  opts.buffer = opts.buffer or opts.buf
  opts.buf = nil
  return setmetatable({
    opts = opts,
  }, map_mt)
end

_M.map      = make_map({ mode = "",  noremap = false })
_M.noremap  = make_map({ mode = "",  noremap = true  })
_M.nmap     = make_map({ mode = "n", noremap = false })
_M.nnoremap = make_map({ mode = "n", noremap = true  })
_M.vmap     = make_map({ mode = "v", noremap = false })
_M.vnoremap = make_map({ mode = "v", noremap = true  })
_M.smap     = make_map({ mode = "s", noremap = false })
_M.snoremap = make_map({ mode = "s", noremap = true  })
_M.xmap     = make_map({ mode = "x", noremap = false })
_M.xnoremap = make_map({ mode = "x", noremap = true  })
_M.omap     = make_map({ mode = "o", noremap = false })
_M.onoremap = make_map({ mode = "o", noremap = true  })
_M.imap     = make_map({ mode = "i", noremap = false })
_M.inoremap = make_map({ mode = "i", noremap = true  })
_M.cmap     = make_map({ mode = "c", noremap = false })
_M.cnoremap = make_map({ mode = "c", noremap = true  })
_M.tmap     = make_map({ mode = "t", noremap = false })
_M.tnoremap = make_map({ mode = "t", noremap = true  })


-- for setting buffer-specific mappings
_M.buf = {
  map      = make_map({ mode = "",  buf = true, noremap = false }),
  noremap  = make_map({ mode = "",  buf = true, noremap = true  }),
  nmap     = make_map({ mode = "n", buf = true, noremap = false }),
  nnoremap = make_map({ mode = "n", buf = true, noremap = true  }),
  vmap     = make_map({ mode = "v", buf = true, noremap = false }),
  vnoremap = make_map({ mode = "v", buf = true, noremap = true  }),
  smap     = make_map({ mode = "s", buf = true, noremap = false }),
  snoremap = make_map({ mode = "s", buf = true, noremap = true  }),
  xmap     = make_map({ mode = "x", buf = true, noremap = false }),
  xnoremap = make_map({ mode = "x", buf = true, noremap = true  }),
  omap     = make_map({ mode = "o", buf = true, noremap = false }),
  onoremap = make_map({ mode = "o", buf = true, noremap = true  }),
  imap     = make_map({ mode = "i", buf = true, noremap = false }),
  inoremap = make_map({ mode = "i", buf = true, noremap = true  }),
  cmap     = make_map({ mode = "c", buf = true, noremap = false }),
  cnoremap = make_map({ mode = "c", buf = true, noremap = true  }),
  tmap     = make_map({ mode = "t", buf = true, noremap = false }),
  tnoremap = make_map({ mode = "t", buf = true, noremap = true  }),
}

---@param f string
---@param key string|number
local function format_key(f, key)
  assert(type(key) == "string" or type(key) == "number")
  key = alias(key)
  return fmt(f, key)
end

---@param label string
---@param k     any
---@param v     any
local function readonly(label, k, v)
  error(fmt("tried to %q = %q on %s namespace", k, v, label), 2)
end


--- Generate a Ctrl+<key> key binding
---
--- Example:
--- ```lua
--- print(Ctrl.t) -- > `<C-t>`
--- ```
---
---@class my.keymap.Ctrl
---
---@field Shift table<string, string>
---@field [string] string
_M.Ctrl = {}

--- Generate a Ctrl+Shift+<key> key binding
---
--- Example:
--- ```lua
--- print(Ctrl.Shift.PageUp) -- > `<C-S-PageUp>`
--- ```
---
---@type table<string, string>
_M.Ctrl.Shift = {}

setmetatable(_M.Ctrl, {
  __index = function(_, k)
    return format_key("<C-%s>", k)
  end,
  __newindex = function(_, k, v)
    readonly("Ctrl", k, v)
  end,
})

setmetatable(_M.Ctrl.Shift, {
  __index = function(_, k)
    return format_key("<C-S-%s>", k)
  end,
  __newindex = function(_, k, v)
    readonly("Ctrl.Shift", k, v)
  end,
})

--- Generate a Shift+<key> key binding
---
--- Example:
--- ```lua
--- print(Shift.Tab) -- > `<S-Tab>`
--- ```
---
---@type table<string, string>
_M.Shift = setmetatable({}, {
  __index = function(_, k)
    return format_key("<S-%s>", k)
  end,
  __newindex = function(_, k, v)
    readonly("Shift", k, v)
  end,
})


--- Generate a Leader-prefixed string
---
--- Example:
--- ```lua
--- print(Leader.t) -- > `<Leader>t`
--- ```
---
---@type table<string, string>
_M.Leader = setmetatable({}, {
  __index = function(_, k)
    return format_key("<Leader>%s", k)
  end,
  __newindex = function(_, k, v)
    readonly("Leader", k, v)
  end,
})

--- Generate a Meta+<key> key binding
---
--- Example:
--- ```lua
--- print(Meta.t) -- > `<M-t>`
--- ```
---
---@type table<string, string>
_M.Meta = setmetatable({}, {
  __index = function(_, k)
    return format_key("<M-%s>", k)
  end,
  __newindex = function(_, k, v)
    readonly("Meta", k, v)
  end,
})

--- Generate an Alt+<key> key binding
---
--- (this is actually aliased to `Meta`)
_M.Alt = _M.Meta


---@param tag string
function _M.remove_by_tag(tag)
  local tags = TAGS[tag]
  if not tags then
    vim.notify(tag .. ": no tags")
    return
  end

  TAGS[tag] = nil

  for _, item in ipairs(tags) do
    if item.buf then
      buf_del_keymap(item.buf, item.mode, item.lhs)
    else
      del_keymap(item.mode, item.lhs)
    end
  end
end


return _M
