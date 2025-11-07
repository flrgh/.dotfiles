-- Eviline config for lualine
-- Author: shadmansaleh
-- Credit: glepnir

local mod = require "my.std.luamod"

local expand                    = vim.fn.expand
local empty                     = vim.fn.empty
local winwidth                  = vim.fn.winwidth
local mode                      = vim.fn.mode
local index                     = vim.fn.index
local finddir                   = vim.fn.finddir
local buf_get_option            = vim.api.nvim_buf_get_option
local lsp_get_clients           = vim.lsp.get_clients
local insert                    = table.insert
local next                      = next

local buffer_not_empty = function()
  return empty(expand('%:t')) ~= 1
end

local function lsp_server_name()
  local msg = "(no LSP)"
  local buf_ft = buf_get_option(0, 'filetype')
  local clients = lsp_get_clients()
  if next(clients) == nil then
    return msg
  end
  for _, client in ipairs(clients) do
    local filetypes = client.config.filetypes
    if filetypes and index(filetypes, buf_ft) ~= -1 then
      return client.name
    end
  end
  return msg
end

local function filename_on_click(nclicks)
  local path = vim.uri_from_bufnr(0):gsub("^file://", "")

  -- basename
  if nclicks == 1 then
    path = path:gsub(".+/", "")

  -- relative to workspace/repo root
  elseif nclicks == 2  then
    local root = vim.fs.root(0, ".git")
                 or vim.fn.getcwd()

    if root and path:find(root, 1, true) == 1 then
      path = path:sub(#root + 1)
      if path:sub(1, 1) == "/" then
        path = path:sub(2)
      end
    end
  end

  vim.fn.setreg("+", path)
  vim.print("Copied '" .. path .. "' to the clipboard")
end

require("lualine").setup({
  options = {
    icons_enabled = true,

    -- different status line per buffer/pane
    globalstatus = false,

    theme = "material",

    disabled_filetypes = { "alpha" },

    -- Disable sections and component separators
    --component_separators = '',
    --section_separators = '',

    always_divide_middle = true,

    refresh = {
      statusline = 1000,
      tabline = 1000,
      winbar = 1000,
    },
  },
  sections = {
    lualine_a = {'mode'},
    lualine_b = {'branch', 'diff', 'diagnostics'},
    lualine_c = { lsp_server_name },
    lualine_x = {
      { "filename",
        cond = buffer_not_empty,
        on_click = filename_on_click,

      },
      { "filetype", },
      { "filesize", cond = buffer_not_empty },
    },
    lualine_y = {'progress'},
    lualine_z = {'location'}
  },
  inactive_sections = {
    -- these are to remove the defaults
    lualine_a = {},
    lualine_b = {},
    lualine_c = {},
    lualine_x = {
      { "filename",
        cond = buffer_not_empty,
        on_click = filename_on_click,
      },
    },
    lualine_y = {},
    lualine_z = {},
  },

  -- to be honest, IDK what these do
  extensions = {
    "fzf",
    "lazy",
    "man",
    "fugitive",
    "quickfix",
  },
})
