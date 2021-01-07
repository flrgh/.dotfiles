local fs = require 'fs'

local expand = vim.fn.expand

local SERVER = expand('~/.config/nvim/bin/lua-lsp')
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
    end

    for _, item in ipairs(opts.extra) do
        local path = expand(item)

        if fs.dir_exists(path) or fs.file_exists(path) then
            libs[path] = true
        end
    end

    return libs
end

return function(on_attach, lsp, caps)
    if not vim.fn.executable(SERVER) then
        return
    end

    local settings = load_user_settings()

    lsp.sumneko_lua.setup {
        on_attach = on_attach,
        capabilities = caps,
        cmd = { SERVER },
        log_level = settings.log_level,
        settings = {
            Lua = {
                runtime = {
                    version = 'LuaJIT', -- neovim implies luajit
                    path = vim.split(package.path, ';'),
                },
                diagnostics = {
                    globals = {
                        'vim',
                        'ngx',

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
                    library = lua_libs(settings.lib),
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
