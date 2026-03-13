local _M = {}

local STATS = {}
_M.STATS = STATS

local patch_get_runtime_file
do
  local CACHE_ALL = {}
  local CACHE_NO_ALL = {}
  local RTP = ""
  local RTPV = 0

  local _default_zero = {
    __index = function(self, k)
      rawset(self, k, 0)
      return 0
    end,
  }

  local HIT = setmetatable({}, _default_zero)
  local MISS = setmetatable({}, _default_zero)
  local stats = {
    HIT = HIT,
    MISS = MISS,
    EXPIRE = RTPV,
  }
  STATS.get_runtime_file = stats

  local function check_rtp(pat)
    local rtp = vim.o.rtp
    if rtp ~= RTP then
      RTP = rtp
      RTPV = RTPV + 1
      stats.EXPIRE = RTPV
      CACHE_ALL = {}
      CACHE_NO_ALL = {}
      return true
    end
    return false
  end

  ---@type fun(name:string, all:boolean):string[]
  local vim_api_nvim_get_runtime_file

  ---@param name string
  ---@param all boolean
  ---@param uncached? boolean
  ---@return string[]
  local function cached_get_runtime_file(name, all, uncached)
    if uncached == true then
      return vim_api_nvim_get_runtime_file(name, all)
    end

    check_rtp()

    local cache = all and CACHE_ALL or CACHE_NO_ALL
    local entry = cache[name]

    if entry then
      HIT[name] = HIT[name] + 1

    else
      MISS[name] = MISS[name] + 1
      entry = vim_api_nvim_get_runtime_file(name, all)
      cache[name] = entry
    end

    return entry
  end

  function patch_get_runtime_file()
    local get = vim.api.nvim_get_runtime_file
    if get == cached_get_runtime_file then
      return
    end

    vim_api_nvim_get_runtime_file = get
    vim.api.nvim_get_runtime_file = cached_get_runtime_file

    local group = vim.api.nvim_create_augroup("my.nvim_get_runtime_file.cache", { clear = true })
    vim.api.nvim_create_autocmd("OptionSet", {
      pattern = "runtimepath",
      callback = function()
        check_rtp()
      end,
    })
  end
end


local function patch_uv()
  local uv = assert(vim.uv)

  ---@class flrgh.nvim.handleinfo
  ---
  ---@field serial integer
  ---@field created number
  ---@field filename string
  ---@field uri string
  ---@field traceback string
  ---@field plugin? string
  ---@field where string
  ---@field buf integer
  ---@field bufname string

  local serial = 0

  local uv_update_time = uv.update_time
  local uv_now = uv.now
  local debug_getinfo = debug.getinfo
  local debug_traceback = debug.traceback
  local nvim_get_current_buf = vim.api.nvim_get_current_buf
  local nvim_buf_get_name = vim.api.nvim_buf_get_name
  local uri_from_fname = vim.uri_from_fname
  local tostring = tostring
  local in_fast_event = vim.in_fast_event

  uv_update_time()

  ---@class my.uv_handle_stats
  local Stats = {
    start_time = uv_now(),
    counts = {
      ---@type table<string, integer>
      handle_type = {},

      ---@type table<string, integer>
      plugin = {},

      ---@type table<string, table<string, integer>>
      plugin_handle_type = {},
    },
    ---@type table<uv.uv_handle_t, flrgh.nvim.handleinfo>
    handles = setmetatable({}, { __mode = "k" }),
  }
  require("my.state").global.uv_handle_stats = Stats

  local handles = Stats.handles
  local total_by_type = Stats.counts.handle_type
  local total_by_plugin = Stats.counts.plugin
  local total_by_plugin_handle = Stats.counts.plugin_handle_type

  for k, v in pairs(uv) do
    if type(v) == "function"
      and k:sub(1, 4) == "new_"
    then
      local fn = v
      local handle_type = k:sub(5)

      uv[k] = function(...)
        local handle = v(...)

        total_by_type[handle_type] = (total_by_type[handle_type] or 0) + 1

        serial = serial + 1
        uv_update_time()
        local created = uv_now()

        local traceback = debug_traceback("", 2)
        local info = debug_getinfo(2)

        local filename = info.source:gsub("^@", "")

        local uri = uri_from_fname(filename)

        local where = filename .. ":" .. tostring(info.currentline)

        -- because it is responsible for loading plugins, lazy.nvim often shows
        -- up in the call stack
        local lazy = "lazy.nvim"
        local seen_non_lazy = false
        local plugins_seen = {}
        local plugin

        for found in traceback:gmatch("/nvim/lazy/([^/]+)/") do
          seen_non_lazy = seen_non_lazy or found ~= lazy

          plugins_seen[found] = true

          if plugin == nil or found ~= lazy then
            plugin = found
          end
        end

        if seen_non_lazy then
          plugins_seen[lazy] = nil
        end

        for name in pairs(plugins_seen) do
          total_by_plugin[name] = (total_by_plugin[name] or 0) + 1

          total_by_plugin_handle[name] = total_by_plugin_handle[name] or {}
          total_by_plugin_handle[name][handle_type] = (total_by_plugin_handle[name][handle_type] or 0) + 1
        end


        local buf, bufname
        if not in_fast_event() then
          buf = nvim_get_current_buf()
          bufname = nvim_buf_get_name(buf)
        end

        handles[handle] = {
          serial = serial,
          created = created,
          traceback = traceback,
          filename = filename,
          uri = uri,
          where = where,
          plugin = plugin,
          buf = buf,
          bufname = bufname,
          stack = stack,
        }

        return handle
      end
    end
  end
end


function _M.stats()
  vim.notify(vim.inspect(STATS))
end

---@param env my.env
function _M.init(env)
  if env and env.editor then
    patch_get_runtime_file()
    patch_uv()
  end
end


return _M
