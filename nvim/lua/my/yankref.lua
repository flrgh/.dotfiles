local vim = vim
local api = vim.api
local fn = vim.fn

local env = require("my.env")
local string = require("my.std.string")
local buffer = require("string.buffer")

local buf_get_lines = api.nvim_buf_get_lines
local buf_get_name = api.nvim_buf_get_name
local get_current_buf = api.nvim_get_current_buf
local get_cursor = api.nvim_win_get_cursor
local max = math.max
local min = math.min
local rep = string.rep
local find = string.find
local gmatch = string.gmatch
local sub = string.sub
local setreg = fn.setreg
local relpath = vim.fs.relpath
local INFO = vim.log.levels.INFO
local WARN = vim.log.levels.WARN

local _M = {}


local CTRL_V = "\022"
local REGISTER_NAMES = {
  ['"'] = "default register",
  ["*"] = "clipboard",
  ["+"] = "clipboard",
}
local REGION_OPTS = { exclusive = false, type = "v" }
local SNIPPET_BUF = buffer.new()

local LANG_ALIASES = {
  javascriptreact = "jsx",
  sh = "bash",
  typescriptreact = "tsx",
}

---@param msg string
local function info(msg)
  vim.notify(msg, INFO)
end

---@param msg string
local function warn(msg)
  vim.notify(msg, WARN)
end


---@param buf integer
---@param absolute? boolean
---@return string|nil
local function filename(buf, absolute)
  local fname = buf_get_name(buf)
  if fname == "" then
    warn("yankref: current buffer has no file name")
    return
  end

  if absolute then
    return fname
  end

  return relpath(env.workspace.dir, fname) or fname
end


---@return string
local function visual_type()
  local mode = fn.mode()
  if mode == "v" or mode == "V" or mode == CTRL_V then
    return mode
  end

  return fn.visualmode()
end


---@return integer start_line
---@return integer end_line
---@return string[] content
local function visual_selection()
  local start_pos = fn.getpos("v")
  local end_pos = fn.getpos(".")

  REGION_OPTS.type = visual_type()

  return min(start_pos[2], end_pos[2]),
         max(start_pos[2], end_pos[2]),
         fn.getregion(start_pos, end_pos, REGION_OPTS)
end


---@param buf integer
---@param ref string
---@param content string[]
---@return string
local function markdown_snippet(buf, ref, content)
  local out = SNIPPET_BUF:reset()

  local fence
  do
    local width = 3

    for i = 1, #content do
      for ticks in gmatch(content[i], "`+") do
        width = max(width, #ticks + 1)
      end
    end

    fence = rep("`", width)
    out:put(fence)
  end

  local filetype = vim.bo[buf].filetype or ""
  out:put(LANG_ALIASES[filetype] or filetype)

  out:put("\n")
  do
    local commentstring = vim.bo[buf].commentstring or ""

    local from, to = find(commentstring, "%s", 1, true)
    if from then
      out:put(sub(commentstring, 1, from - 1))
        :put(ref)
        :put(sub(commentstring, to + 1))

    else
      out:put("# ", ref)
    end
  end
  out:put("\n")

  for i = 1, #content do
    out:put(content[i], "\n")
  end

  out:put(fence)

  return out:get()
end


---@param text string
---@param ref string
local function copy(text, ref)
  local reg = vim.v.register
  local name = REGISTER_NAMES[reg] or ("register " .. reg)

  setreg(reg, text)
  info("copied " .. ref .. " to " .. name)
end


---@param buf integer
---@param file string
---@param snippet? boolean
---@param start_line integer
---@param end_line integer
---@param force_range? boolean
---@param content string[]
local function yank_text(buf, file, snippet, start_line, end_line, force_range, content)
  local ref
  if force_range or start_line ~= end_line then
    ref = file .. ":" .. start_line .. "-" .. end_line
  else
    ref = file .. ":" .. start_line
  end

  if snippet then
    return copy(markdown_snippet(buf, ref, content), ref)
  end

  return copy(ref, ref)
end


---@param absolute? boolean
function _M.yank_path(absolute)
  local buf = get_current_buf()
  local fname = filename(buf, absolute)
  if fname then
    copy(fname, fname)
  end
end


---@param absolute? boolean
---@param snippet? boolean
function _M.yank_line(absolute, snippet)
  local buf = get_current_buf()
  local fname = filename(buf, absolute)
  if not fname then
    return
  end

  local lineno = get_cursor(0)[1]
  local content = buf_get_lines(buf, lineno - 1, lineno, false)
  return yank_text(buf, fname, snippet, lineno, lineno, false, content)
end


---@param absolute? boolean
---@param snippet? boolean
function _M.yank_selection(absolute, snippet)
  local buf = get_current_buf()
  local fname = filename(buf, absolute)
  if not fname then
    return
  end

  local start_line, end_line, content = visual_selection()
  return yank_text(buf, fname, snippet, start_line, end_line, true, content)
end


return _M
