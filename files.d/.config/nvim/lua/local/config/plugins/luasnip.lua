local _M = {}

local mod = require "local.module"

local ls
local types

function _M.setup()
  if not mod.exists("luasnip") then
    return
  end

  ls = require "luasnip"
  types = require "luasnip.util.types"

  ls.config.set_config {
    history = true,

    updateevents = "TextChanged,TextChangedI",

    enable_autosnippets = true,

    ext_opts = {
      [types.choiceNode] = {
        active = {
          virt_text = { { "<-", "Error" } },
        }
      }
    },
  }

  _M.snippets()

  local function expand()
    ls = require "luasnip"
    if ls.expand_or_jumpable() then
      ls.expand_or_jump()
    end
  end

  local function back()
    ls = require "luasnip"
    if ls.jumpable(-1) then
      ls.jump(-1)
    end
  end

  local function list()
    ls = require "luasnip"
    if ls.choice_active() then
      ls.change_choice(1)
    end
  end

  local km = require("local.module").reload("local.keymap")
  km.imap.ctrl.k = { expand, silent = true }
  km.smap.ctrl.k = { expand, silent = true }

  km.imap.ctrl.j = { back, silent = true }
  km.smap.ctrl.j = { back, silent = true }

  km.imap.ctrl.l = { list, silent = true }
  km.smap.ctrl.l = { list, silent = true }

  km.nnoremap[km.Leader .. km.Leader .. "s"] = function()
    local mod = require "local.module"
    mod.reload("local.config.plugins.luasnip").snippets()
    vim.notify("snippets reloaded!")
  end
end

function _M.snippets()
  ls = require "luasnip"

  local s = ls.s
  local fmt = require("luasnip.extras.fmt").fmt
  local ins = ls.insert_node
  local rep = require("luasnip.extras").rep

	ls.snippets = {
		all = {},
		lua = {
			ls.parser.parse_snippet("lf", "local function $1($2)\n  $0\nend"),

      s("req", fmt([[local {} = require "{}"]], { ins(1), rep(1) } )),
		},
	}
end

return _M
