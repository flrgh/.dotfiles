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


local _M = {}

local CR = "<CR>"

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
---@param action string
---@param opts? vim.api.keyset.keymap
---@param buf? boolean
local function save_tagged(mode, lhs, _action, opts, buf)
  local tag = opts.tag
  opts.tag = nil
  if not tag then
    return
  end

  TAGS[tag] = TAGS[tag] or {}

  local bufid
  if buf then
    bufid = get_current_buf()
  end

  insert(TAGS[tag], {
    mode = mode,
    lhs = lhs,
    buf = bufid,
  })
end


---@param mode string
---@param key string
---@param action string
---@param opts? vim.api.keyset.keymap
---@param buf? boolean
local function create_keymap(mode, key, action, opts, buf)
  if opts.tag then
    save_tagged(mode, key, action, opts, buf)
  end

  if buf then
    return buf_set_keymap(0, mode, key, action, opts)
  else
    return set_keymap(mode, key, action, opts)
  end
end

local EMPTY = {}

---@param v any
---@return boolean
local function is_callable(v)
  local typ = type(v)

  if typ == "function" then
    return true

  elseif typ == "string" then
    return false

  elseif v == nil then
    return false
  end

  return type(getmetatable(v) or EMPTY).__call == "function"
end


local mt = {
  __newindex = function(self, key, v)
    if v == nil then
      return
    end

    local action = v
    local opts

    if type(v) == 'table' then
      action = v[1]
      v[1] = nil
      opts = v
    end

    opts = opts or {}

    if action == nil then
      return
    end

    opts.desc = opts.desc or opts[2]
    opts[2] = nil

    opts.tag = opts.tag or opts[3]
    opts[3] = nil

    if is_callable(action) then
      opts = vim.deepcopy(opts)
      opts.callback = action
      action = ""
    end

    if not opts.no_auto_cr then
      -- auto-append Enter/<CR> to commands
      if startswith(action, ':') then
        if not endswith(action:upper(), CR) then
          action = action .. CR
        end
      end
    end

    opts.no_auto_cr = nil

    return create_keymap(
      self.mode or '',
      key,
      action,
      extend(self.opts, opts),
      self.buf
    )
  end
}


---@alias my.keymap.mode "n"|"v"|"x"|"i"|"o"|""

---@class my.keymap.opts : vim.api.keyset.keymap
---
---@field buf?        boolean
---@field no_auto_cr? boolean
---@field desc?       string
---@field tag?        string

---@class my.keymap.action.table : my.keymap.opts
---@field [1] string|function # the RHS of the key map
---@field [2] string|nil      # shorthand for desc = ...
---@field [3] string|nil      # shorthand for tag = ...

---@alias my.keymap.action string|my.keymap.action.table

---@alias my.keymap.binding table<string, my.keymap.action>

---@class my.keymap : table
---@field ctrl     my.keymap.binding
---@field fn       my.keymap.binding
---@field leader   my.keymap.binding
---@field mode     my.keymap.mode
---@field opts     my.keymap.opts


---@param mode string
---@param opts my.keymap.opts
---@return my.keymap.binding
local function make_map(mode, opts)
  local buf = opts.buf or false
  opts.buf = nil
  return setmetatable({
    mode = mode,
    opts = opts,
    buf  = buf,
  }, mt)
end

_M.map      = make_map('',  { noremap = false })
_M.noremap  = make_map('',  { noremap = true  })
_M.nmap     = make_map('n', { noremap = false })
_M.nnoremap = make_map('n', { noremap = true  })
_M.vmap     = make_map('v', { noremap = false })
_M.vnoremap = make_map('v', { noremap = true  })
_M.smap     = make_map('s', { noremap = false })
_M.snoremap = make_map('s', { noremap = true  })
_M.xmap     = make_map('x', { noremap = false })
_M.xnoremap = make_map('x', { noremap = true  })
_M.omap     = make_map('o', { noremap = false })
_M.onoremap = make_map('o', { noremap = true  })
_M.imap     = make_map('i', { noremap = false })
_M.inoremap = make_map('i', { noremap = true  })
_M.cmap     = make_map('c', { noremap = false })
_M.cnoremap = make_map('c', { noremap = true  })
_M.tmap     = make_map('t', { noremap = false })
_M.tnoremap = make_map('t', { noremap = true  })


-- for setting buffer-specific mappings
_M.buf = {
  map      = make_map('',  { buf = true, noremap = false }),
  noremap  = make_map('',  { buf = true, noremap = true  }),
  nmap     = make_map('n', { buf = true, noremap = false }),
  nnoremap = make_map('n', { buf = true, noremap = true  }),
  vmap     = make_map('v', { buf = true, noremap = false }),
  vnoremap = make_map('v', { buf = true, noremap = true  }),
  smap     = make_map('s', { buf = true, noremap = false }),
  snoremap = make_map('s', { buf = true, noremap = true  }),
  xmap     = make_map('x', { buf = true, noremap = false }),
  xnoremap = make_map('x', { buf = true, noremap = true  }),
  omap     = make_map('o', { buf = true, noremap = false }),
  onoremap = make_map('o', { buf = true, noremap = true  }),
  imap     = make_map('i', { buf = true, noremap = false }),
  inoremap = make_map('i', { buf = true, noremap = true  }),
  cmap     = make_map('c', { buf = true, noremap = false }),
  cnoremap = make_map('c', { buf = true, noremap = true  }),
  tmap     = make_map('t', { buf = true, noremap = false }),
  tnoremap = make_map('t', { buf = true, noremap = true  }),
}

--- Generate a Ctrl+<key> key binding
---
--- Example:
--- ```lua
--- print(Ctrl.t) -- > `<C-t>`
--- ```
---
---@type table<string, string>
_M.Ctrl = setmetatable({}, {
  __index = function(_, k)
    assert(type(k) == "string" or type(k) == "number")
    k = alias(k)
    return fmt("<C-%s>", k)
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
    assert(type(k) == "string" or type(k) == "number")
    k = alias(k)
    return fmt("<S-%s>", k)
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
    assert(type(k) == "string" or type(k) == "number")
    k = alias(k)
    return fmt("<Leader>%s", k)
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
    assert(type(k) == "string" or type(k) == "number")
    return fmt("<M-%s>", k)
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
