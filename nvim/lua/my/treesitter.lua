local _M  = {}

_M.languages = {
  "awk",
  "bash",
  "c",
  "c_sharp",
  "capnp",
  "cmake",
  "comment",
  "commonlisp",
  "cpp",
  "css",
  "csv",
  "cue",
  "desktop",
  "devicetree",
  "diff",
  "dockerfile",
  "editorconfig",
  "git_config",
  "git_rebase",
  "gitattributes",
  "gitcommit",
  "gitignore",
  "go",
  "gomod",
  "gosum",
  "gpg",
  "hcl",
  "html",
  "http",
  "ini",
  "java",
  "javascript",
  "jq",
  "json",
  "json5",
  "jsonc",
  "julia",
  "linkerscript",
  "lua",
  "make",
  "markdown",
  "markdown_inline",
  "nginx",
  "ninja",
  "nix",
  "objdump",
  "passwd",
  "perl",
  "php",
  "python",
  "query", -- parser for treesitter queries
  "regex",
  "rst",
  "rust",
  "sql",
  "ssh_config",
  "starlark",
  "strace",
  "teal",
  "terraform",
  "tmux",
  "toml",
  "tsv",
  "typescript",
  "udev",
  "vim",
  "vimdoc",
  "xml",
  "yaml",
  "zig",
}


function _M.bootstrap()
  require('nvim-treesitter.configs').setup {
    ---@diagnostic disable-next-line
    modules = nil,

    ensure_installed = _M.languages,
    ignore_install = {
      "swift",
    },
    sync_install = true,
    auto_install = true,
  }
end

function _M.setup()
  local path = require("my.std.path")
  local plugins = require("my.plugins")

  local textobjects
  if plugins.installed("nvim-treesitter-textobjects") then
    textobjects = {
      select = {
        enable = true,

        -- Automatically jump forward to textobj, similar to targets.vim
        lookahead = true,

        keymaps = {
          -- You can use the capture groups defined in textobjects.scm
          ["af"] = "@function.outer",
          ["if"] = "@function.inner",
          ["ac"] = "@class.outer",
          -- You can optionally set descriptions to the mappings (used in the desc parameter of
          -- nvim_buf_set_keymap) which plugins like which-key display
          ["ic"] = { query = "@class.inner", desc = "Select inner part of a class region" },
          -- You can also use captures from other query groups like `locals.scm`
          ["as"] = { query = "@local.scope", query_group = "locals", desc = "Select language scope" },
        },
        -- You can choose the select mode (default is charwise 'v')
        --
        -- Can also be a function which gets passed a table with the keys
        -- * query_string: eg '@function.inner'
        -- * method: eg 'v' or 'o'
        -- and should return the mode ('v', 'V', or '<c-v>') or a table
        -- mapping query_strings to modes.
        selection_modes = {
          ['@parameter.outer'] = 'v', -- charwise
          ['@function.outer'] = 'V', -- linewise
          ['@class.outer'] = '<c-v>', -- blockwise
        },
        -- If you set this to `true` (default is `false`) then any textobject is
        -- extended to include preceding or succeeding whitespace. Succeeding
        -- whitespace has priority in order to act similarly to eg the built-in
        -- `ap`.
        --
        -- Can also be a function which gets passed a table with the keys
        -- * query_string: eg '@function.inner'
        -- * selection_mode: eg 'v'
        -- and should return true or false
        include_surrounding_whitespace = true,
      },
    }
  end

  require("nvim-treesitter.configs").setup {
    ---@diagnostic disable-next-line
    modules = nil,

    textobjects = textobjects,

    ensure_installed = {},
    ignore_install = {},
    sync_install = false,
    auto_install = false,

    highlight = {
      enable = true,
      -- disable for files >= 100K
      disable = function(_lang, buf)
        local max = 1024 * 100
        local fname = path.buffer_filename(buf)
        if fname and path.size(fname) > max then
          return true
        end

        return false
      end,
    },
    incremental_selection = {
      enable = true,
      keymaps = {
        init_selection = "ss",

        node_incremental = "+",
        node_decremental = "-",

        scope_incremental = "++",
      },
    },
    indent = {
      enable = false,
      disable = {
        "lua", -- 2021-01-02: treesitter overindents tables
      }
    },
    context_commentstring = {
      enable = true,
      enable_autocmd = false,
    },
  }

  vim.opt.foldmethod = "expr"
  vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
  vim.opt.foldenable = false
  vim.opt.foldnestmax = 3
  vim.opt.foldminlines = 4

  if plugins.installed("nvim-treesitter-context") then
    require("treesitter-context").setup {
       -- Enable this plugin (Can be enabled/disabled later via commands)
      enable = true,
      -- How many lines the window should span. Values <= 0 mean no limit.
      max_lines = 0,
       -- Minimum editor window height to enable context. Values <= 0 mean no limit.
      min_window_height = 0,
      line_numbers = true,
       -- Maximum number of lines to show for a single context
      multiline_threshold = 20,
       -- Which context lines to discard if `max_lines` is exceeded. Choices: 'inner', 'outer'
      trim_scope = "outer",
      -- Line used to calculate context. Choices: 'cursor', 'topline'
      mode = "cursor",
      -- Separator between context and content. Should be a single character string, like '-'.
      -- When separator is set, the context will only show up when there are at least 2 lines above cursorline.
      separator = "-",
      -- The Z-index of the context window
      zindex = 20,
      -- (fun(buf: integer): boolean) return false to disable attaching
      on_attach = nil,
    }
  end
end

return _M
