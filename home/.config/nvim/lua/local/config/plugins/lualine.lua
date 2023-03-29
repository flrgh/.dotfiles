-- Eviline config for lualine
-- Author: shadmansaleh
-- Credit: glepnir

local mod = require "local.module"

local expand                    = vim.fn.expand
local empty                     = vim.fn.empty
local winwidth                  = vim.fn.winwidth
local mode                      = vim.fn.mode
local index                     = vim.fn.index
local finddir                   = vim.fn.finddir
local buf_get_option            = vim.api.nvim_buf_get_option
local lsp_get_active_clients    = vim.lsp.get_active_clients
local insert                    = table.insert
local next                      = next


local DEFAULT_COLORS = {
  bg       = '#202328',
  fg       = '#bbc2cf',
  yellow   = '#ECBE7B',
  cyan     = '#008080',
  darkblue = '#081633',
  green    = '#98be65',
  orange   = '#FF8800',
  violet   = '#a9a1e1',
  magenta  = '#c678dd',
  blue     = '#51afef',
  red      = '#ec5f67',
}


local function init()

  local colors

  ---@class ayu.colors : table
  ---
  ---@field accent             string
  ---@field bg                 string
  ---@field fg                 string
  ---@field ui                 string
  ---@field tag                string
  ---@field func               string
  ---@field entity             string
  ---@field string             string
  ---@field regexp             string
  ---@field markup             string
  ---@field keyword            string
  ---@field special            string
  ---@field comment            string
  ---@field constant           string
  ---@field operator           string
  ---@field error              string
  ---@field line               string
  ---@field panel_bg           string
  ---@field panel_shadow       string
  ---@field panel_border       string
  ---@field gutter_normal      string
  ---@field gutter_active      string
  ---@field selection_bg       string
  ---@field selection_inactive string
  ---@field selection_border   string
  ---@field guide_active       string
  ---@field guide_normal       string
  ---@field vcs_added          string
  ---@field vcs_modified       string
  ---@field vcs_removed        string
  ---@field vcs_added_bg       string
  ---@field vcs_removed_bg     string
  ---@field fg_idle            string
  ---@field warning            string
  ---
  ---@field generate           fun(boolean)

  local using_ayu = false

  if mod.exists("ayu") then
    using_ayu = true
    ---@type ayu.colors
    local ayu = require "ayu.colors"
    if not ayu.accent then
      ayu.generate(true)
    end
    colors = setmetatable(ayu, { __index = DEFAULT_COLORS })

  else
    colors = DEFAULT_COLORS
  end

  -- Config
  local config = {
    options = {
      globalstatus = true,
      disabled_filetypes = { "lazy", "alpha" },

      -- Disable sections and component separators
      component_separators = '',
      section_separators = '',
      theme = {
        normal = { c = { fg = colors.fg, bg = colors.bg } },
        inactive = { c = { fg = colors.fg, bg = colors.bg } },
      },
    },
    sections = {
      -- these are to remove the defaults
      lualine_a = {},
      lualine_b = {},
      lualine_y = {},
      lualine_z = {},
      -- These will be filled later
      lualine_c = {},
      lualine_x = {},
    },
    inactive_sections = {
      -- these are to remove the defaults
      lualine_a = {},
      lualine_b = {},
      lualine_y = {},
      lualine_z = {},
      lualine_c = {},
      lualine_x = {},
    },
  }

  if using_ayu then
    local theme = require "lualine.themes.ayu"
    for k, v in pairs(theme) do
      config.options.theme[k] = config.options.theme[k] or v
    end
  end


  local conditions = {
    buffer_not_empty = function()
      return empty(expand('%:t')) ~= 1
    end,
    hide_in_width = function()
      return winwidth(0) > 80
    end,
    check_git_workspace = function()
      local filepath = expand('%:p:h')
      local gitdir = finddir('.git', filepath .. ';')
      return gitdir and #gitdir > 0 and #gitdir < #filepath
    end,
  }


  -- Inserts a component in lualine_c at left section
  local function ins_left(component)
    insert(config.sections.lualine_c, component)
  end

  -- Inserts a component in lualine_x ot right section
  local function ins_right(component)
    insert(config.sections.lualine_x, component)
  end

  ins_left {
    function()
      return '▊'
    end,
    color = { fg = colors.blue }, -- Sets highlighting of component
    padding = { left = 0, right = 1 }, -- We don't need space before this
  }

  do
    local mode_color = {
      n = colors.red,
      i = colors.green,
      v = colors.blue,
      [''] = colors.blue,
      V = colors.blue,
      c = colors.magenta,
      no = colors.red,
      s = colors.orange,
      S = colors.orange,
      [''] = colors.orange,
      ic = colors.yellow,
      R = colors.violet,
      Rv = colors.violet,
      cv = colors.red,
      ce = colors.red,
      r = colors.cyan,
      rm = colors.cyan,
      ['r?'] = colors.cyan,
      ['!'] = colors.red,
      t = colors.red,
    }

    ins_left {
      -- mode component
      function()
        return ''
      end,
      color = function()
        -- auto change color according to neovims mode
        return { fg = mode_color[mode()] }
      end,
      padding = { right = 1 },
    }
  end

  ins_left {
    -- filesize component
    'filesize',
    cond = conditions.buffer_not_empty,
  }

  ins_left {
    'filename',
    cond = conditions.buffer_not_empty,
    color = { fg = colors.magenta, gui = 'bold' },
  }

  ins_left { 'location' }

  ins_left { 'progress', color = { fg = colors.fg, gui = 'bold' } }

  ins_left {
    'diagnostics',
    sources = { 'nvim_diagnostic' },
    symbols = { error = ' ', warn = ' ', info = ' ' },
    diagnostics_color = {
      color_error = { fg = colors.red },
      color_warn = { fg = colors.yellow },
      color_info = { fg = colors.cyan },
    },
  }

  -- Insert mid section. You can make any number of sections in neovim :)
  -- for lualine it's any number greater then 2
  ins_left {
    function()
      return '%='
    end,
  }

  ins_left {
    -- Lsp server name .
    function()
      local msg = 'No Active Lsp'
      local buf_ft = buf_get_option(0, 'filetype')
      local clients = lsp_get_active_clients()
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
    end,
    icon = ' LSP:',
    color = { fg = '#ffffff', gui = 'bold' },
  }

  -- Add components to right sections
  ins_right {
    'o:encoding', -- option component same as &encoding in viml
    fmt = string.upper, -- I'm not sure why it's upper case either ;)
    cond = conditions.hide_in_width,
    color = { fg = colors.green, gui = 'bold' },
  }

  ins_right {
    'fileformat',
    fmt = string.upper,
    icons_enabled = false, -- I think icons are cool but Eviline doesn't have them. sigh
    color = { fg = colors.green, gui = 'bold' },
  }

  ins_right {
    'branch',
    icon = '',
    color = { fg = colors.violet, gui = 'bold' },
  }

  ins_right {
    'diff',
    -- Is it me or the symbol for modified us really weird
    symbols = { added = ' ', modified = '柳 ', removed = ' ' },
    diff_color = {
      added = { fg = colors.green },
      modified = { fg = colors.orange },
      removed = { fg = colors.red },
    },
    cond = conditions.hide_in_width,
  }

  ins_right {
    function()
      return '▊'
    end,
    color = { fg = colors.blue },
    padding = { left = 1 },
  }

  return config
end


return {
  setup = function()
    require("lualine").setup(init())
  end,
}
