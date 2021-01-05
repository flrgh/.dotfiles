local lsp = require 'lspconfig'
local lsp_status = require 'lsp-status'

local function set_key_maps(_)
    local options = {
        noremap = true,
        silent = true
    }

    local mappings = {
        n = {
            ['<c-]>'] = 'definition',
            ['gD']    = 'implementation',
            ['<c-k>'] = 'signature_help',
            ['gd']    = 'declaration',
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


local function find_lua_libraries()
    local libs = {
        -- Make the server aware of Neovim runtime files
        [vim.fn.expand('$VIMRUNTIME/lua')] = true,
        [vim.fn.expand('$VIMRUNTIME/lua/vim/lsp')] = true,
    }

    local git_dirs = vim.fn.globpath('~/git', '**/.git', false, true)

    for _, g in ipairs(git_dirs) do
        g = g:gsub('/%.git$', '')
        if vim.fn.globpath(g, '**/*.lua') ~= '' then
            libs[g] = true
        end
    end

    return libs
end

lsp.sumneko_lua.setup {
    on_attach = on_attach,
    cmd = {
        vim.fn.expand('~/.config/nvim/bin/lua-lsp'),
    },
    settings = {
        Lua = {
            runtime = {
                -- Tell the language server which version of Lua you're using (LuaJIT in the case of Neovim)
                version = 'LuaJIT',
                -- Setup your lua path
                path = vim.split(package.path, ';'),
            },
            diagnostics = {
                -- Get the language server to recognize the `vim` global
                globals = {
                    'vim',
                    'ngx',
                },
            },
            workspace = {
                library = find_lua_libraries(),
            },
            telemetry = {
                -- don't phone home
                enable = false,
            },
        },
    },
}

if vim.fn.executable("gopls") then
    lsp.gopls.setup {
        on_attach = on_attach,
        capabilities = lsp_status.capabilities
    }
end

if vim.fn.executable("terraform-ls") then
    lsp.terraformls.setup({})
end

if vim.fn.executable("bash-language-server") then
    lsp.bashls.setup {
        on_attach = on_attach
    }
end

lsp_status.register_progress()
