# luarocks config
export LUAROCKS_CONFIG=$CONFIG_HOME/luarocks/config.lua

# init script for the lua REPL
if [[ -f $CONFIG_HOME/lua/repl.lua ]]; then
    export LUA_INIT="@$CONFIG_HOME/lua/repl.lua"
fi

if [[ -d ~/git/flrgh/lua-utils ]]; then
    addPath "$HOME/git/flrgh/lua-utils/lib/?.lua;$HOME/git/flrgh/lua-utils/lib/?.init.lua" LUA_PATH ";"
fi

LUAROCKS=$(type -f -p luarocks)
if [[ -n $LUAROCKS ]]; then
    rocks_path=$HOME/.config/lua/rocks_path

    if [[ ! -e $rocks_path ]] || [[ $LUAROCKS -nt $rocks_path ]]; then
        luarocks path --lr-path \
        | tr ';' '\n' \
        > "$rocks_path"
    fi

    rocks_cpath=$HOME/.config/lua/rocks_cpath
    if [[ ! -e $rocks_cpath ]] || [[ $LUAROCKS -nt $rocks_cpath ]]; then
        luarocks path --lr-cpath \
        | tr ';' '\n' \
        > "$rocks_cpath"
    fi

    while read -r path; do
        addPath "$path" LUA_PATH ";"
    done < "$rocks_path"

    while read -r path; do
        addPath "$path" LUA_CPATH ";"
    done < "$rocks_cpath"
fi
