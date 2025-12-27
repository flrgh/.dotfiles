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

function _M.stats()
  vim.notify(vim.inspect(STATS))
end

---@param env my.env
function _M.init(env)
  if env and env.editor then
    patch_get_runtime_file()
  end
end


return _M
