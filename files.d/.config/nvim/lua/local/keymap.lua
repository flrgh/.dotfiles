local fmt        = string.format
local startswith = vim.startswith
local endswith   = vim.endswith

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

local function create_keymap(mode, key, action, opts, buf)
  local handler, maps

  if buf then
    handler = vim.api.nvim_buf_set_keymap
    maps = registry.buf
  else
    handler = vim.api.nvim_set_keymap
    maps = registry
  end

  return handler(mode, key, action, opts)
end

local registry = { n = 0 }

local function add_fn(fn)
  local id = registry.n + 1
  registry[id] = fn
  registry.n = id
  return id
end

local function call_fn(id)
  local fn = assert(registry[id], "function with id " .. id .. " not found")
  return fn()
end

local function fn_handler(fn)
  local id = add_fn(fn)
  return fmt([[<cmd>lua require("local.keymap").call_fn(%s)<CR>]], id)
end


local mt = {
  __newindex = function(self, key, v)
    if self.set_key then
      key = self.set_key(key)
    end

    local action = v
    local opts

    if type(v) == 'table' then
      action = v[1]
      v[1] = nil
      opts = v
    end

    if type(action) == "function" then
      action = fn_handler(action)
    end

    opts = opts or {}

    if not opts.no_auto_cr then
      -- auto-append <CR> to commands
      if startswith(action, ':') then
        if not endswith(action:upper(), '<CR>') then
          action = action .. '<CR>'
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

---@param t string
---@return local.keymap.set_key
local function template(t)
  return function(key)
    return t:format(key)
  end
end

local wrap_ctrl = template('<C-%s>')
local wrap_fn = template('<%s>')
local add_leader = template('<Leader>%s')

---@alias local.keymap.set_key fun(s:string):string

---@alias local.keymap.mode '"n"'|'"v"'|'"x"'|'""'

---@class local.keymap.opts : table
---@field noremap boolean
---@field silent  boolean
---@field nowait  boolean
---@field script  boolean
---@field expr    boolean
---@field unique  boolean

---@class local.keymap.action.table : local.keymap.opts
---@field [1] string # the RHS of the key map

---@alias local.keymap.action string|local.keymap.action.table

---@alias local.keymap.binding table<string, local.keymap.action>

---@class local.keymap : table
---@field ctrl     local.keymap.binding
---@field fn       local.keymap.binding
---@field leader   local.keymap.binding
---@field mode     local.keymap.mode
---@field opts     local.keymap.opts
---@field set_key? local.keymap.set_key

---@return local.keymap
local function make_map(mode, opts)
  return setmetatable({
    mode = mode,
    opts = opts,

    ctrl = setmetatable(
      {
        mode    = mode,
        opts    = opts,
        set_key = wrap_ctrl,
      },
      mt
    ),

    fn = setmetatable(
      {
        mode    = mode,
        opts    = opts,
        set_key = wrap_fn,
      },
      mt
    ),

    leader = setmetatable(
      {
        mode    = mode,
        opts    = opts,
        set_key = add_leader,
      },
      mt
    ),
  }, mt)
end

local map      = make_map('',  { noremap = false })
local vmap     = make_map('v', { noremap = false })
local nmap     = make_map('n', { noremap = false })
local noremap  = make_map('',  { noremap = true })
local vnoremap = make_map('v', { noremap = true })
local nnoremap = make_map('n', { noremap = true })
local xmap     = make_map('x', { noremap = false })
local imap     = make_map('i', { noremap = false })
local smap     = make_map('s', { noremap = false })

---@type table<string,table>
local lsp_functions = setmetatable({}, {
  __index = function(_, k)
    if not vim.lsp.buf[k] then
      error("unknown function `vim.lsp.buf." .. k .. "()`")
    end
    return {
      fmt('<cmd>lua vim.lsp.buf.%s()<CR>', k),
      silent = true,
    }
  end,
})

---@type table<string, string>
local ctrl = setmetatable({}, {
  __index = function(_, k)
    return wrap_ctrl(k)
  end,
})

return {
  map  = map,
  nmap = nmap,
  vmap = vmap,
  xmap = xmap,
  imap = imap,
  smap = smap,

  noremap  = noremap,
  nnoremap = nnoremap,
  vnoremap = vnoremap,


  setup = function(fn)
    fn(map, nmap, vmap, noremap, nnoremap, vnoremap, xmap)
  end,

  lsp = lsp_functions,

  Ctrl  = ctrl,
  Enter = '<CR>',
  Tab   = '<Tab>',
  S_Tab = '<S-Tab>',
  Leader = '<leader>',

  call_fn = call_fn,
}
