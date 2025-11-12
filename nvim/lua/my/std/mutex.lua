local wait = vim.wait
local ceil = math.ceil

---@class my.std.mutex
local _M = {}

---@param max_timeout? integer
---@return my.std.NamedMutex
function _M.named(max_timeout)
  max_timeout = max_timeout or 10000 -- 10s

  ---@type { [string]: boolean }
  local _locks = {}

  local function _unlocked(key)
    return function()
      return _locks[key] ~= true
    end
  end

  ---@param key string
  local function acquire(key)
    assert(type(key) == "string")

    local timeout = 10
    local interval = 1
    local waited = 0

    local is_unlocked = _unlocked(key)

    while _locks[key] == true do
      wait(timeout, is_unlocked, interval)

      if not _locks[key] then break end

      waited = waited + timeout
      assert(waited < max_timeout, "timed out acquiring lock")

      timeout = ceil(timeout * 1.5)
      interval = ceil(interval * 1.5)
    end

    assert(not _locks[key])
    _locks[key] = true
  end

  ---@param key string
  local function release(key)
    assert(_locks[key] == true)
    _locks[key] = nil
  end

  ---@class my.std.NamedMutex
  local mutex = {
    acquire = acquire,
    release = release,
  }

  return mutex
end


---@param max_timeout? integer
---@return my.std.Mutex
function _M.new(max_timeout)
  max_timeout = max_timeout or 10000 -- 10s

  local _locked = false

  local function is_locked()
    return _locked == true
  end

  local function is_unlocked()
    return _locked == false
  end

  local function acquire()
    local timeout = 10
    local interval = 1
    local waited = 0

    while _locked do
      wait(timeout, is_unlocked, interval)
      if _locked == false then break end

      waited = waited + timeout
      assert(waited < max_timeout, "timed out acquiring lock")

      timeout = ceil(timeout * 1.5)
      interval = ceil(interval * 1.5)
    end

    assert(_locked == false)
    _locked = true
  end

  local function release()
    assert(_locked == true)
    _locked = false
  end

  ---@class my.std.Mutex
  local mutex = {
    acquire = acquire,
    release = release,
    locked = is_locked,
    unlocked = is_unlocked,
  }

  return mutex
end

return _M
