# luarocks config
export LUAROCKS_CONFIG=$CONFIG_HOME/luarocks/config.lua

# init script for the lua REPL
if [[ -f $CONFIG_HOME/lua/repl.lua ]]; then
    export LUA_INIT="@$CONFIG_HOME/lua/repl.lua"
fi

if [[ -d ~/.local/share/luajit-2.1 ]]; then
    __rc_add_path LUA_PATH ~/.local/share/luajit-2.1/?.lua
fi
