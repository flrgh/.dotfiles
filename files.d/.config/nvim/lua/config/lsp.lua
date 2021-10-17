-- don't configure or start lsp if vim is running in headless mode
if #vim.api.nvim_list_uis() == 0 then
  return
end

local lsp        = require 'lspconfig'
local lsp_status = require 'lsp-status'
local saga       = require 'lspsaga'


saga.init_lsp_saga({})

--[[
compe.setup({
  enabled          = true,
  autocomplete     = true,
  debug            = false,
  min_length       = 1,
  preselect        = 'enable',
  throttle_time    = 80,
  source_timeout   = 200,
  incomplete_delay = 400,
  max_abbr_width   = 100,
  max_kind_width   = 100,
  max_menu_width   = 100,
  documentation    = true,

  source = {
    -- common
    --buffer = true,
    buffer = {kind = "  "},
    --calc   = false,
    calc = {kind = "  "},
    omni   = false,
    --path   = true,
    path = {kind = "  "},
    spell  = {kind = " 🔤 ", filetypes={"markdown", "text"}},
    tags   = false,
    --vsnip  = true,
    vsnip = {kind = "  "},

    -- Neovim-specific
    -- nvim_lsp = true,
    nvim_lsp = {kind = "  "},
    nvim_lua = true,

    -- External-plugin
    ["nvim-treesitter"] = false,
    ["snippets.nvim"]   = false,
    snippets_nvim       = false,
    ["vim-vsnip"]       = false,
    ultisnips           = false,
    vim_lsc             = false,
    vim_lsp             = false,
    emoji = {kind = " ﲃ ", filetypes={"markdown", "text"}},

    -- External sources
    ["latex-symbols"] = false,
    conjure           = false,
    dadbod            = false,
    tabnine           = false,
    zsh               = false,

  },
})
]]--

---@alias local.lsp.on_attach fun(client: table)

---@type local.lsp.on_attach
local function set_key_maps()
    local options = {
        noremap = true,
        silent = true
    }

    local mappings = {
        n = {
            ['<c-]>'] = 'definition',
            ['gD']    = 'implementation',
            ['gd']    = 'declaration',
            ['K']     = 'hover',
        }
    }

    for mode, maps in pairs(mappings) do
        for key, fn in pairs(maps) do
            vim.api.nvim_set_keymap(
                mode,
                key,
                string.format('<cmd>lua vim.lsp.buf.%s()<CR>', fn),
                options
            )
        end
    end

    vim.cmd('setlocal omnifunc=v:lua.vim.lsp.omnifunc')
end


---@param funcs local.lsp.on_attach[]
---@return local.lsp.on_attach
local function attach_all(funcs)
    return function(client)
        for _, attach in ipairs(funcs) do
            attach(client)
        end
    end
end

local on_attach = attach_all({
  lsp_status.on_attach,
  set_key_maps,
})

--local caps = lsp_status.capabilities

local caps = vim.lsp.protocol.make_client_capabilities()
caps = require('cmp_nvim_lsp').update_capabilities(caps)

require('lsp.lua')(on_attach, lsp, caps)
require('lsp.go')(on_attach, lsp, caps)
require('lsp.terraform')(on_attach, lsp, caps)
require('lsp.bash')(on_attach, lsp, caps)
require('lsp.python')(on_attach, lsp, caps)
require('lsp.yaml')(on_attach, lsp, caps)
require('lsp.json')(on_attach, lsp, caps)
require('lsp.sql')(on_attach, lsp, caps)
require('lsp.teal')(on_attach, lsp, caps)

lsp_status.register_progress()
