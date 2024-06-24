local mod = require "my.utils.luamod"

if not mod.exists("telescope") then
  return
end

local ts = require "telescope"

ts.setup({
  extensions = {
    fzf = {
      fuzzy                   = true,         -- false will only do exact matching
      override_generic_sorter = false,        -- override the generic sorter
      override_file_sorter    = true,         -- override the file sorter
      case_mode               = "smart_case", -- or "ignore_case" or "respect_case"
      -- the default case_mode is "smart_case"
    }
  }
})

-- To get fzf loaded and working with telescope, you need to call
-- load_extension, somewhere after setup function:
ts.load_extension('fzf')
