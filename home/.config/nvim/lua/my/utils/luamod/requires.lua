local _M = {}

local type = type
local pairs = pairs
local insert = table.insert
local pcall = pcall

local vim = vim
local api = vim.api


---@type vim.treesitter.Query
local query

local get_parser = vim.treesitter.get_parser
local parse_query = vim.treesitter.query.parse
local get_node_text = vim.treesitter.get_node_text

local query_text = [[
(function_call
    name: (identifier) @func (#eq? @func "require")
    arguments: (arguments
      (string
        content: (string_content) @mod
    )
  )
)
]]

local query_opts = { all = true }

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
---@return string[]?
function _M.get_module_requires(buf)
  local lang = get_parser(buf, "lua")

  local syn = lang:parse()
  local root = syn[1]:root()

  query = query or assert(parse_query("lua", query_text))

  local result = {}
  local ok, iter = pcall(query.iter_matches, query, root, 0, 0, -1, query_opts)
  if not ok then
     vim.notify(vim.inspect({
       message = "error getting text from buffer",
       buf     = buf,
       file    = api.nvim_buf_get_name(buf),
       error   = iter,
     }), vim.log.levels.WARN)
    return result
  end

  local pattern, match, metadata
  while true do
    ok, pattern, match, metadata = pcall(iter, pattern, match, metadata)

    if not ok then
       vim.notify(vim.inspect({
         message = "error getting text from buffer",
         buf     = buf,
         file    = api.nvim_buf_get_name(buf),
         error   = pattern,
       }), vim.log.levels.WARN)
      return result
    end

    if not pattern or not match then break end

    local res = {}
    assert(#match == 2)

    for id, nodes in pairs(match) do
      local name = query.captures[id]

      assert(#nodes == 1)
      local text
      ok, text = pcall(get_node_text, nodes[1], buf)
      if ok then
        res[name] = text
      else
        vim.notify(vim.inspect({
          message = "error getting text from buffer",
          buf     = buf,
          file    = api.nvim_buf_get_name(buf),
          error   = text,
        }), vim.log.levels.WARN)
      end
    end

    if is_require(res) then
      insert(result, res.mod)
    end
  end

  return result
end


return _M
