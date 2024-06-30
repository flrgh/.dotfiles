local _M = {}

local vim = vim
local nvim_buf_get_lines = vim.api.nvim_buf_get_lines
local nvim_buf_set_text = vim.api.nvim_buf_set_text

local find = string.find
local insert = table.insert

local EMPTY = {}

---@param buf? integer # default to current buffer
function _M.strip_whitespace(buf)
  buf = buf or 0

  if vim.bo.readonly or not vim.bo[buf].modifiable then
    return
  end

  local lines = nvim_buf_get_lines(buf, 0, -1, true)

  ---@type { row:integer, from:integer, to: integer }
  local edits = {}

  for i = 1, #lines do
    local line = lines[i]
    local from, to = find(line, "%s+$")

    if from then
      insert(edits, {
        row = i - 1,
        from = from - 1,
        to = to,
      })
    end
  end

  for i = 1, #edits do
    local edit = edits[i]
    nvim_buf_set_text(buf, edit.row, edit.from, edit.row, edit.to, EMPTY)
  end
end

return _M
