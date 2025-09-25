local _M = {}

local type = type
local pairs = pairs
local insert = table.insert
local pcall = pcall
local sort = table.sort

local vim = vim
local api = vim.api
local ts = vim.treesitter
local WARN = vim.log.levels.WARN


local QUERY_TEXT = [[
(function_call
    name: (identifier) @func (#eq? @func "require")
    arguments: (arguments
      (string
        content: (string_content) @mod
    )
  )
)
]]

local QUERY_OPTS = { all = true }

---@type vim.treesitter.Query
local QUERY

local PARSE_OPTS = { error = false }


---@param res { func: string, mod: string }
local function is_require(res)
  return
    res.func == "require"
    and type(res.mod) == "string"
    -- If the module finder runs while I'm in the middle of typing, and I have
    -- an un-terminated string:
    --
    -- ```
    -- local mod = require("my.module<CURSOR>
    -- ```
    --
    -- ...tree-sitter will consume the remainder of the buffer and consider it
    -- the param to `require()`. This filters out the garbage data.
    and #res.mod < 255
    and res.mod:find("^[%a%d%p/]+$")
end


---@param buf integer
---@param msg string
---@param err any
local function warn(buf, msg, err)
  vim.notify(vim.inspect({
    buf     = buf,
    file    = api.nvim_buf_get_name(buf),
    message = msg,
    error   = err,
  }), WARN)
end


---@param buf integer
---@param src? integer|string
---@param unique? boolean
---@return string[]?
local function run_query(buf, src, unique)
  buf = buf or 0

  if buf == 0 then
    buf = api.nvim_get_current_buf()
  end

  if not api.nvim_buf_is_loaded(buf) then
    return
  end

  src = src or buf

  local err

  ---@type vim.treesitter.Query
  local query = QUERY

  if not QUERY then
    QUERY, err = ts.query.parse("lua", QUERY_TEXT)
    if not QUERY then
      warn(buf, "failed parsing query", err)
      return
    end
    query = QUERY
  end

  ---@type TSNode
  local root

  do
    ---@type vim.treesitter.LanguageTree
    local parser
    if type(src) == "string" then
      parser, err = ts.get_string_parser(src, "lua", PARSE_OPTS)
    else
      parser, err = ts.get_parser(buf, "lua", PARSE_OPTS)
    end

    if not parser then
      warn(buf, "failed parsing buffer", err)
      return
    end

    local trees = parser:parse(true)
    root = assert(trees[1]:root())
  end

  local results = {}
  local seen = {}

  for pattern, match, metadata in query:iter_matches(root, src, 0, -1, QUERY_OPTS) do
    if not pattern or not match then
      break
    end

    if not api.nvim_buf_is_loaded(buf) then
      warn(buf, "stopped iterating matches", "buffer was unloaded")
      break
    end


    local res = {}
    assert(#match == 2)

    for id, nodes in pairs(match) do
      assert(#nodes == 1)

      local name = query.captures[id]

      local ok, text = pcall(ts.get_node_text, nodes[1], src)
      if ok then
        res[name] = text
      else
        warn(buf, "error getting text from buffer", text)
      end
    end

    if is_require(res) and (not unique or not seen[res.mod]) then
      insert(results, res.mod)
      seen[res.mod] = true
    end
  end

  return results
end


---@return string|nil
function _M.get_line_requires()
  local buf = api.nvim_get_current_buf()
  local line = api.nvim_get_current_line()
  local results = run_query(buf, line)
  if results then
    return results[1]
  end
end


---@param buf integer
---@return string[]?
function _M.get_module_requires(buf)
  local results = run_query(buf, buf, true)
  if results then
    sort(results)
  end
  return results
end


return _M
