local _M = {}

local vim = vim
local deepcopy = vim.deepcopy
local type = type
local json_encode = vim.json.encode

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
    return inspect(item, opts)
  end
end

local time
do
  local update_time = vim.uv.update_time
  local now = vim.uv.now

  function time()
    update_time()
    return now()
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
    return (item.method and ignored[item.method])
        or (item.request and item.request.method and ignored[item.request.method])
  end
end

local client_reqs = {}
local server_reqs = {}

local sending = false
local receiving = false

---@type string
local fname

---@type file*
local fh


function _M.init()
  fname = os.getenv("NVIM_LSP_DEBUG_LOG") or "my.lsp.log"
  fh = assert(io.open(fname, "a+"))
end


function _M.log(item)
  assert(fh, "log file not opened")

  if not sending and not receiving then
    sending   = item == "rpc.send"
    receiving = item == "rpc.receive"
    return format(item)
  end

  local evt = sending and "send" or "recv"
  sending = false
  receiving = false

  if type(item) ~= "table" then
    return format(item)
  end

  if ignore(item) then
    return format(item)
  end

  item = deepcopy(item)
  item.event = evt

  local id = item.id or -1

  local client_response = evt == "send"
                      and item.result
                      and true
                       or false

  local client_request = evt == "send"
                     and not client_response

  local server_request = evt == "recv"
                     and item.params
                     and true
                      or false

  local server_response = evt == "recv"
                      and not server_request


  if client_response then
    local req = server_reqs[id]
    server_reqs[id] = nil

    if req then
      item.request = req
      req.latency = time() - req.received
    end

  elseif client_request then
    client_reqs[id] = {
      id = id,
      method = item.method,
      sent = time(),
    }

    if item.method == "$/cancelRequest" then
      local req_id = item.params and item.params.id
      if req_id  then
        local req = client_reqs[req_id]
        if req then
          req.sent_cancel = time()
          req.canceled_after = req.sent_cancel - req.sent
          item.canceled = req
        end
      end
    end

  elseif server_request then
    server_reqs[id] = {
      id = id,
      method = item.method,
      received = time(),
    }

  elseif server_response then
    local req = client_reqs[id]
    client_reqs[id] = nil

    if req then
      item.request = req
      req.latency = time() - req.sent
    end
  end

  if not ignore(item) then
    fh:write(vim.json.encode(item) .. "\n")
    fh:flush()
  end

  return format(item)
end

return _M
