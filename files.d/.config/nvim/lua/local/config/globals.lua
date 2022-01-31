local globals = {}

--- nvim workspace directory
---@type string|nil
globals.workspace = nil

do
  local mod = require "local.module"
  local ws

  if mod.exists("lspconfig") then
    local util = require "lspconfig.util"
    local f = vim.fn.expand("%:p:h")
    ws = util.find_git_ancestor(f)
  end

  local fs = require 'local.fs'
  if not ws then
    ws = fs.workspace_root()
  end

  if not ws then
    ws = fs.buffer_directory()
  end

  if ws then
    vim.fn.setenv("NVIM_WORKSPACE", ws)
    globals.workspace = ws
  end
end
