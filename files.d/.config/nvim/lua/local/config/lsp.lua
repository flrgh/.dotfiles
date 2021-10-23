-- don't configure or start lsp if vim is running in headless mode
if #vim.api.nvim_list_uis() == 0 then
  return
end

local lsp        = require 'lspconfig'
local lsp_status = require 'lsp-status'
local saga       = require 'lspsaga'

saga.init_lsp_saga({})

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

require('local.lsp.lua')(on_attach, lsp, caps)
require('local.lsp.go')(on_attach, lsp, caps)
require('local.lsp.terraform')(on_attach, lsp, caps)
require('local.lsp.bash')(on_attach, lsp, caps)
require('local.lsp.python')(on_attach, lsp, caps)
require('local.lsp.yaml')(on_attach, lsp, caps)
require('local.lsp.json')(on_attach, lsp, caps)
require('local.lsp.sql')(on_attach, lsp, caps)
require('local.lsp.teal')(on_attach, lsp, caps)

lsp_status.register_progress()
