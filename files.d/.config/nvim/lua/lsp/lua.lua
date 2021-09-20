local fs = require 'fs'

local expand = vim.fn.expand

local SERVER = 'lua-language-server'
local USER_SETTINGS = expand('~/.config/lua/sumneko.json')

local DEFAULT_SETTINGS = {
    lib = {
        include_vim = true, -- Make the server aware of Neovim runtime files
        extra = {},
    },
    log_level = 2,
}

local function merge(t, extra)
    if type(t) == 'table' and type(extra) == 'table' then
        for k, v in pairs(extra) do
            t[k] = merge(t[k], v)
        end
        return t
    end

    return extra
end

local function load_user_settings()
    local settings = DEFAULT_SETTINGS
    if not fs.file_exists(USER_SETTINGS) then
        return settings
    end

    local user = fs.read_json_file(USER_SETTINGS)
    if not user then
        return settings
    end

    return merge(settings, user)
end

local function lua_libs(opts)
    local libs = {}
    if opts.include_vim then
        libs[expand('$VIMRUNTIME/lua')] = true
        libs[expand('$VIMRUNTIME/lua/vim/lsp')] = true
        libs[expand('$HOME/.config/nvim/lua')] = true
    end

    for _, item in ipairs(opts.extra) do
        libs[expand(item)] = true
    end

    libs[expand("$PWD")] = true
    libs[expand("$PWD/lua")] = true
    libs[expand("$PWD/src")] = true

    return libs
end

return function(on_attach, lsp, caps)
    if not vim.fn.executable(SERVER) then
        return
    end

    local settings = load_user_settings()

    local library = lua_libs(settings.lib)

    local path = vim.split(package.path, ';')

    for lib in pairs(library) do
      table.insert(path, lib .. '/?.lua')
      table.insert(path, lib .. '/?/init.lua')
    end

    lsp.sumneko_lua.setup {
        on_attach = on_attach,
        capabilities = caps,
        cmd = { SERVER },
        log_level = settings.log_level,
        settings = {
            Lua = {
                runtime = {
                    version = 'LuaJIT', -- neovim implies luajit
                    path = path,
                },
                completion = {
                    enable = true,
                },
                signatureHelp = {
                    enable = true,
                },
                hover = {
                    enable = true,
                },
                diagnostics = {
                    enable = true,
                    disable = {
                        'lowercase-global',
                    },
                    globals = {
                        'vim',

                        -- openresty/kong globals
                        'ngx',
                        'kong',

                        -- busted globals
                        'after_each',
                        'before_each',
                        'describe',
                        'expose',
                        'finally',
                        'insulate',
                        'it',
                        'lazy_setup',
                        'lazy_teardown',
                        'mock',
                        'pending',
                        'pending',
                        'randomize',
                        'setup',
                        'spec',
                        'spy',
                        'strict_setup',
                        'strict_teardown',
                        'stub',
                        'teardown',
                        'test',

                    },
                },
                workspace = {
                    library = library,
                    ignoreSubmodules = false,
                },
                telemetry = {
                    -- don't phone home
                    enable = false,
                },
            },
        },
    }
end
