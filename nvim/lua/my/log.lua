---@class my.log
local _M = {}

local vim = vim
local levels = vim.lsp.log.levels
local in_fast_event = vim.in_fast_event

---@class my.log.notify
_M.notify = {}


return _M
