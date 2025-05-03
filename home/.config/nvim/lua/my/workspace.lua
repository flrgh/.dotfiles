---@class my.workspace : table
---
---@field dir string # fully-qualified workspace directory path
---@field basename string # last path element of the workspace
---@field meta my.workspace.meta
local WS = {}

local fs = require "my.utils.fs"
local g = require "my.config.globals"

---@alias my.workspace.meta table<string, any>

---@class my.workspace.matcher
---
---@field match fun(ws:my.workspace):boolean
---@field meta? my.workspace.meta
---@field last? boolean

local function match_dir_exact(dir)
  return function(ws)
    return ws.dir == dir
  end
end

local function substr(subject, sub)
  return subject:find(sub, nil, true) ~= nil
end

---@type my.workspace.matcher[]
local matchers = {
  {
    match = function(ws)
      return ws.dir == g.git_user_root .. "/doorbell"
    end,
    meta = {
      doorbell = true,
      resty = true,
      lua = true,
    },
  },

  {
    -- ~/git/.dotfiles
    match = function(ws)
      return ws.dir == g.dotfiles.root
    end,
    meta = {
      nvim     = true,
      dotfiles = true,
      lua      = true,
    },
    last = true,
  },

  {
    -- anything to do with OpenResty
    match = function(ws)
      return substr(ws.dir, "resty")
          or substr(ws.dir, "ngx")
          or substr(ws.dir, "nginx")
          or substr(ws.dir, "OpenResty")
    end,
    meta = {
      resty = true,
      lua = true,
    },
  },

  {
    -- ~/git/kong/*
    match = function(ws)
      local check = g.git_root .. "/kong"
      return ws.dir:find(check, nil, true) == 1
    end,
    meta = {
      kong = true,
      resty = true,
      lua = true,
    },
  },

  {
    match = function(ws)
      return ws.basename == "lua-language-server"
    end,
    meta = {
      luarc = true,
      lua = true,
    },
  },

  {
    match = function(ws)
      return substr(ws.dir, "neovim")
          or substr(ws.dir, "nvim")
    end,
    meta = {
      nvim = true,
      lua = true,
    },
  },

  {
    match = function(ws)
      return substr(ws.dir, "blj")
    end,
    meta = {
      lua = true,
      blj = true,
    },
  },

  {
    match = function(ws)
      return fs.file_exists(fs.join(ws.dir, ".busted"))
    end,
    meta = {
      busted = true,
    },
  },
}

if not WS.dir then
  local dir = assert(g.workspace)
  assert(fs.dir_exists(dir))

  WS.dir = assert(fs.realpath(dir))
  WS.basename = fs.basename(dir)
  WS.meta = {}

  for i = 1, #matchers do
    local m = matchers[i]
    if m.match(WS) then
      for k, v in pairs(m.meta) do
        WS.meta[k] = v
      end

      if m.last then
        break
      end
    end
  end
end

return WS
