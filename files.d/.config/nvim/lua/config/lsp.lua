local lsp = require 'lspconfig'
local lsp_status = require 'lsp-status'
local saga = require 'lspsaga'

local executable = vim.fn.executable

saga.init_lsp_saga({})

local function set_key_maps(_)
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

local function attach_all(funcs)
    return function(client)
        for _, attach in ipairs(funcs) do
            attach(client)
        end
    end
end

local on_attach = attach_all {
    require('completion').on_attach,
    lsp_status.on_attach,
    set_key_maps,
}

local caps = lsp_status.capabilities

require('lsp.lua')(on_attach, lsp, caps)
require('lsp.go')(on_attach, lsp, caps)
require('lsp.terraform')(on_attach, lsp, caps)
require('lsp.bash')(on_attach, lsp, caps)
require('lsp.python')(on_attach, lsp, caps)
require('lsp.yaml')(on_attach, lsp, caps)
require('lsp.json')(on_attach, lsp, caps)
require('lsp.sql')(on_attach, lsp, caps)

lsp_status.register_progress()
