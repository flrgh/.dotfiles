local _M = {}

local vim = vim
local api = vim.api
local type = type
local json_encode = vim.json.encode
local NULL = vim.NIL
local evt = require "my.event"

---@type luv_work_ctx_t
local queue

local format
do
  local inspect = vim.inspect

  -- omit the metatable from vim.inspect outoupt
  local METATABLE = inspect.METATABLE
  local opts = {
    process = function(item, path)
      if path[#path] ~= METATABLE then return item end
    end
  }

  function format(item)
    local typ = type(item)
    if typ == "number" or typ == "string" or typ == "boolean" then
      return tostring(item)
    end
    return inspect(item, opts)
  end
end

local time
do
  local update_time = vim.uv.update_time
  local hrtime = vim.uv.hrtime

  function time()
    update_time()
    return hrtime() / 1e9
  end
end

local ignore
do
  local ignored = {
    ["$/status/report"]                = true,
    ["$/progress"]                     = true,
    ["$/status/show"]                  = true,
    ["window/workDoneProgress/create"] = true,
  }

  function ignore(item)
    return ignored[item]
        or (item.method and ignored[item.method])
        or (item.request and item.request.method and ignored[item.request.method])
  end
end

local function log_server_stderr(prefix, cmd, event, chunk)
  local entry

  if prefix == "rpc" then
    if event == "stderr" then
      chunk = chunk:gsub("[\r\n]+$", "")
    end

    entry = {
      command = cmd,
      event = event,
      data = chunk,
    }

  else
    return
  end

  if ignore(entry) then
    return
  end

  queue:queue(_M.fname, json_encode(entry))
end


local function wrap(handler)
  return function(...)
    log_server_stderr(...)
    return handler(...)
  end
end

_M.fname = "my.lsp.log"

function _M.init()
  _M.fname = os.getenv("NVIM_LSP_DEBUG_LOG") or _M.fname

  queue = assert(vim.uv.new_work(
    function(fname, entry)
      assert(require("my.utils.fs").append_file(fname, entry .. "\n"))
    end,
    function() end
  ))

  -- monkey-patch log functions so that we can access the whole log entry
  do
    local log = require "vim.lsp.log"
    log.debug = wrap(log.debug)
    log.error = wrap(log.error)
    log.info = wrap(log.info)
    log.trace = wrap(log.trace)
    log.warn = wrap(log.warn)

    log.set_format_func(format)
  end

  local rpc = require "vim.lsp.client"
  local _request = rpc._request

  ---@type table<integer, table<integer, my.lsp.logger.entry>>
  local in_flight = {}

  rpc._request = function(self, method, params, handler, bufnr)
    if ignore(method) then
      return _request(self, method, params, handler, bufnr)
    end

    handler = handler or assert(
      self:_resolve_handler(method),
      string.format('not found: %q request handler for client %q.', method, self.name)
    )

    local client_id = self.id
    in_flight[client_id] = in_flight[client_id] or {}

    local sent = time()
    ---@class my.lsp.logger.entry
    local entry = {
      request = {
        ---@type integer
        id = nil,
        ---@type string
        method = method,
        ---@type table?
        params = params,
      },
      sent = sent,
      ---@type number?
      duration = nil,
      ---@type string|table|nil
      error = nil,
      ---@type table?
      response = nil,
      client = {
        ---@type integer
        id = client_id,
        ---@type string
        name = self.name,
      },
      ---@type "init"|"complete"|"cancel"|"sent"|"error"
      status = "init",
    }

    local request_id

    ---@param err string?
    ---@param result table?
    ---@param context table?
    local function wrapper(err, result, context)
      entry.error = err or NULL
      entry.response = result or NULL

      entry.duration = time() - sent
      entry.sent = nil
      entry.status = err and "error" or "complete"

      queue:queue(_M.fname, json_encode(entry))

      return handler(err, result, context)
    end

    local ok
    ok, request_id = _request(self, method, params, wrapper, bufnr)

    if ok then
      entry.status = "sent"
    else
      entry.status = "error"
    end

    entry.request.id = request_id
    in_flight[client_id][request_id] = entry

    return ok, request_id
  end

  local group = api.nvim_create_augroup("DebugLSP", { clear = true })

  api.nvim_create_autocmd(evt.LspRequest, {
    group = group,
    callback = function(e)
      local client_id = e.data.client_id
      local request_id = e.data.request_id
      local request = e.data.request

      local entry = in_flight[client_id]
                and in_flight[client_id][request_id]

      if not entry then
        return
      end

      if request.type == "cancel" then
        entry.status = "cancel"
        entry.duration = time() - entry.sent
        entry.sent = nil

        queue:queue(_M.fname, json_encode(entry))
        in_flight[client_id][request_id] = nil

      elseif request.type == "complete" then
        in_flight[client_id][request_id] = nil
      end
    end,
  })

  vim.schedule(function()
    vim.notify("LSP debugging enabled. Log file:\n" .. _M.fname)
  end)
end

return _M
