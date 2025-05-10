if require("my.constants").bootstrap then
  return
end

local event = require "my.event"

local vim = vim
local api = vim.api
local create_augroup = api.nvim_create_augroup
local create_autocmd = api.nvim_create_autocmd
local fmt = string.format


---@class _vim.autocmd.event
---@field id     number  autocommand id
---@field event  string  event name
---@field group? number  autocommand group id
---@field match  string  expanded value of <amatch>
---@field buf    number  expanded value of <abuf>
---@field file   string  expanded value of <afile>
---@field data?  table

---@class _vim.autocmd.command
---@field desc      string
---@field event?    string
---@field events?   string[]
---@field pattern   string|string[]
---@field buffer?   number
---@field callback  fun(event:_vim.autocmd.event):boolean?
---@field command?  string
---@field once?     boolean
---@field nested?   boolean

---@param name string
---@param cmds _vim.autocmd.command[]
local function create(name, cmds)
  local gid = create_augroup(name, {})
  for i, cmd in ipairs(cmds) do
    local opts = {
      group    = gid,
      pattern  = cmd.pattern,
      buffer   = cmd.buffer,
      desc     = cmd.desc or fmt("%s autocmd %s/%s", name, i, #cmds),
      callback = cmd.callback,
      command  = cmd.command,
      once     = cmd.once,
      nested   = cmd.nested,
    }

    local evt = cmd.event or cmd.events
    create_autocmd(evt, opts)
  end
end

do
  create("user-nomodified", {
    {
      desc = "Manage fileencoding + modifiable + modified",
      events = {event.BufNewFile, event.BufRead},
      pattern = "*",
      callback = function()
        local bo = vim.bo

        -- IDK why this is necessary, but setting buffer `fileencoding` for the
        -- first time always sets `modified`, so this forcibly sets it and
        -- then resets `nomodified`
        if not bo.fileencoding or bo.fileencoding == "" then
          if bo.modifiable then
            bo.fileencoding = "utf-8"
            bo.modified = false
          end
        end

        -- when run with -R, set `nomodifiable`
        if vim.o.readonly then
          bo.modifiable = false
        end
      end,
    },

    {
      desc = "Set nomodified+nomodifiable when reading from stdin",
      event = event.StdinReadPost,
      pattern = "*",
      callback = function()
        vim.bo.modifiable = false
        vim.bo.modified = false
      end,
    },
  })
end

do
  create("user-lsp", {
    {
      desc = "forward LSP attach/detach events",
      events = { event.LspAttach, event.LspDetach },
      pattern = "*",
      callback = function(e)
        require("my.lsp.helpers").route_event(e)
      end,
    },
  })
end
