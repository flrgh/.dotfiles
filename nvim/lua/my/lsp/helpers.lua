local _M = {}

local event = require "my.event"

local vim = vim
local api = vim.api
local lsp = vim.lsp

local function forward_event(src, buf, client_id, client_name)
  local name, pattern = event.user_event(src, client_name)

  api.nvim_exec_autocmds(name, {
    pattern = pattern,
    modeline = false,
    data = {
      buffer = buf,
      client_id = client_id,
      client_name = client_name,
    },
  })
end
forward_event = vim.schedule_wrap(forward_event)


---@param e _vim.autocmd.event
---@param client_name string
---@return vim.lsp.Client?
local function get_client(e, client_name)
  if not e then return end

  local data = e.data
  local id = data and data.client_id

  if not id then
    vim.notify("got a " .. e.event .. " event for " .. client_name
               .. " but with no client id",
               vim.log.levels.WARN)
    return

  elseif data.client_name and data.client_name ~= client_name then
    vim.notify("got a " .. e.event .. " event for " .. data.client_name
               .. ", but I am listening for " .. client_name,
               vim.log.levels.WARN)
    return
  end

  local client = lsp.get_client_by_id(id)
  if not client then
    vim.notify("client " .. tostring(id) .. " disappeared before "
               .. " I could handle the " .. e.event .. " event for "
               .. client_name,
               vim.log.levels.WARN)
    return
  end

  return client
end


---@param evt string
---@param client_name string
---@param fn fun(client: vim.lsp.Client, buf:number)
local function register(evt, client_name, fn)
  local name, pattern = event.user_event(evt, client_name)

  event.on(name)
    :group(name .. "." .. pattern)
    :pattern(pattern)
    :callback(vim.schedule_wrap(function(e)
      local client = get_client(e, client_name)
      if not client then
        return
      end

      local buf = e.data and e.data.buffer or e.buf
      fn(client, buf)
    end))
end


---@param name string
---@param fn fun(client: vim.lsp.Client, buf:number)
function _M.on_detach(name, fn)
  register(event.LspDetach, name, fn)
end


---@param name string
---@param fn fun(client: vim.lsp.Client, buf:number)
function _M.on_attach(name, fn)
  register(event.LspAttach, name, fn)
end


---@param e _vim.autocmd.event
function _M.route_event(e)
  local client_id = e.data and e.data.client_id
  if not client_id then
    return
  end

  local buf = e.buf

  if e.event == event.LspAttach then
    require("my.lsp").on_attach(client_id, buf)

  elseif e.event == event.LspDetach then
    require("my.lsp").on_detach(client_id, buf)

  else
    vim.notify("unknown event: " .. e.event, vim.log.levels.WARN)
    return
  end

  local client = lsp.get_client_by_id(client_id)
  if not client then
    return
  end

  forward_event(e.event,  buf, client_id, client.name)
end

return _M
