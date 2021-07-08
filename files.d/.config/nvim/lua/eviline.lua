local gl = require('galaxyline')

local vim = vim
local fn = vim.fn

local colors = {
  bg       = '#202328',
  fg       = '#bbc2cf',
  yellow   = '#fabd2f',
  cyan     = '#008080',
  darkblue = '#081633',
  green    = '#98be65',
  orange   = '#FF8800',
  violet   = '#a9a1e1',
  magenta  = '#c678dd',
  blue     = '#51afef',
  red      = '#ec5f67',
}

local mode_color = {
	n      = colors.magenta,
	i      = colors.green,
	v      = colors.blue,
	[''] = colors.blue,
	V      = colors.blue,
	c      = colors.red,
	no     = colors.magenta,
	s      = colors.orange,
	S      = colors.orange,
	[''] = colors.orange,
	ic     = colors.yellow,
	R      = colors.purple,
	Rv     = colors.purple,
	cv     = colors.red,
	ce     = colors.red,
	r      = colors.cyan,
	rm     = colors.cyan,
	['r?'] = colors.cyan,
	['!']  = colors.red,
	t      = colors.red,
}

local buffer_not_empty = function()
  if fn.empty(fn.expand('%:t')) ~= 1 then
    return true
  end
  return false
end

local checkwidth = function()
  local squeeze_width  = fn.winwidth(0) / 2
  if squeeze_width > 40 then
    return true
  end
  return false
end


gl.short_line_list = {'NvimTree','vista','dbui'}
local gls = gl.section

gls.left = {
  {
    RainbowRed = {
      provider = function() return '▊ ' end,
      highlight = {colors.blue,colors.bg}
    },
  },

  {
    ViMode = {
      provider = function()
        -- auto change color according the vim mode
        vim.api.nvim_command('hi GalaxyViMode guifg='..mode_color[fn.mode()])
        return '  '
      end,
      highlight = {colors.red,colors.bg,'bold'},
    },
  },

  {
    FileSize = {
      provider = 'FileSize',
      condition = buffer_not_empty,
      highlight = {colors.fg,colors.bg}
    }
  },

  {
    FileIcon = {
      provider = 'FileIcon',
      condition = buffer_not_empty,
      highlight = {require('galaxyline.provider_fileinfo').get_file_icon_color,colors.bg},
    },
  },

  {
    FileName = {
      provider = {'FileName'},
      condition = buffer_not_empty,
      highlight = {colors.green,colors.bg,'bold'}
    }
  },

  {
    LineInfo = {
      provider = 'LineColumn',
      separator = ' ',
      separator_highlight = {'NONE',colors.bg},
      highlight = {colors.fg,colors.bg},
    },
  },

  {
    PerCent = {
      provider = 'LinePercent',
      separator = ' ',
      separator_highlight = {'NONE',colors.bg},
      highlight = {colors.fg,colors.bg,'bold'},
    }
  },

  {
    DiagnosticError = {
      provider = 'DiagnosticError',
      icon = '  ',
      highlight = {colors.red,colors.bg}
    }
  },

  {
    DiagnosticWarn = {
      provider = 'DiagnosticWarn',
      icon = '  ',
      highlight = {colors.yellow,colors.bg},
    }
  },

  {
    DiagnosticHint = {
      provider = 'DiagnosticHint',
      icon = '  ',
      highlight = {colors.cyan,colors.bg},
    }
  },

  {
    DiagnosticInfo = {
      provider = 'DiagnosticInfo',
      icon = '  ',
      highlight = {colors.blue,colors.bg},
    }
  },
}

gls.right = {
  {
    FileEncode = {
      provider = 'FileEncode',
      separator = ' ',
      separator_highlight = {'NONE',colors.bg},
      highlight = {colors.cyan,colors.bg,'bold'}
    }
  },

  {
    FileFormat = {
      provider = 'FileFormat',
      separator = ' ',
      separator_highlight = {'NONE',colors.bg},
      highlight = {colors.cyan,colors.bg,'bold'}
    }
  },

  {
    GitIcon = {
      provider = function() return '  ' end,
      condition = require('galaxyline.provider_vcs').check_git_workspace,
      separator = ' ',
      separator_highlight = {'NONE',colors.bg},
      highlight = {colors.violet,colors.bg,'bold'},
    }
  },

  {
    GitBranch = {
      provider = 'GitBranch',
      condition = require('galaxyline.provider_vcs').check_git_workspace,
      highlight = {colors.violet,colors.bg,'bold'},
    }
  },

  {
    DiffAdd = {
      provider = 'DiffAdd',
      condition = checkwidth,
      icon = '  ',
      highlight = {colors.green,colors.bg},
    }
  },

  {
    DiffModified = {
      provider = 'DiffModified',
      condition = checkwidth,
      icon = '  ',
      highlight = {colors.orange,colors.bg},
    }
  },

  {
    DiffRemove = {
      provider = 'DiffRemove',
      condition = checkwidth,
      icon = '  ',
      separator = ' ',
      highlight = {colors.red,colors.bg},
    }
  },

  {
    RainbowBlue = {
      provider = function() return ' ▊' end,
      highlight = {colors.blue,colors.bg}
    },
  },
}

gls.short_line_left = {
  {
    BufferType = {
      provider = 'FileTypeName',
      separator = ' ',
      separator_highlight = {'NONE',colors.bg},
      highlight = {colors.blue,colors.bg,'bold'}
    }
  },

  {
    SFileName = {
      provider = function ()
        local fileinfo = require('galaxyline.provider_fileinfo')
        local fname = fileinfo.get_current_file_name()
        for _,v in ipairs(gl.short_line_list) do
          if v == vim.bo.filetype then
            return ''
          end
        end
        return fname
      end,
      condition = buffer_not_empty,
      highlight = {colors.white,colors.bg,'bold'}
    }
  },

  {
    BufferIcon = {
      provider= 'BufferIcon',
      highlight = {colors.fg,colors.bg}
    }
  },
}
