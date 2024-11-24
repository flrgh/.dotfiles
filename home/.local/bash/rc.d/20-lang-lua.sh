# luarocks config
export LUAROCKS_CONFIG=$CONFIG_HOME/luarocks/config.lua

# init script for the lua REPL
if [[ -f $CONFIG_HOME/lua/repl.lua ]]; then
    export LUA_INIT="@$CONFIG_HOME/lua/repl.lua"
fi

luarocks=$(type -f -p luarocks)
if [[ -n $luarocks ]]; then
    rocks_path=$HOME/.config/lua/rocks_path

    if [[ ! -s $rocks_path ]] || [[ $luarocks -nt $rocks_path ]]; then
        luarocks path --lr-path \
        | tr ';' '\n' \
        > "$rocks_path"
    fi

    rocks_cpath=$HOME/.config/lua/rocks_cpath
    if [[ ! -s $rocks_cpath ]] || [[ $luarocks -nt $rocks_cpath ]]; then
        luarocks path --lr-cpath \
        | tr ';' '\n' \
        > "$rocks_cpath"
    fi

    rocks_bin=$HOME/.config/lua/rocks_bin
    if [[ ! -s $rocks_bin ]] || [[ $luarocks -nt $rocks_bin ]]; then
        luarocks path --lr-bin \
        | tr ';' '\n' \
        > "$rocks_bin"
    fi

    while read -r path; do
        __rc_add_path "$path" LUA_PATH
    done < "$rocks_path"

    while read -r path; do
        __rc_add_path "$path" LUA_CPATH
    done < "$rocks_cpath"

    while read -r path; do
        __rc_add_path "$path" PATH
    done < "$rocks_bin"

    unset path rocks_path rocks_cpath rocks_bin
fi
unset luarocks

luajit=$(type -f -p luajit)
if [[ -n $luajit ]]; then
    lj_base=$(realpath "$luajit")
    lj_include="$HOME/.local/share/${lj_base##*/}"

    if [[ -d "$lj_include" ]]; then
        __rc_add_path "$lj_include/?.lua" LUA_PATH
    fi

    unset lj_base lj_include
fi
unset luajit

if [[ -d ~/git/flrgh/lua-utils ]]; then
    __rc_add_path "$HOME/git/flrgh/lua-utils/lib/?/init.lua" LUA_PATH --prepend
    __rc_add_path "$HOME/git/flrgh/lua-utils/lib/?.lua"      LUA_PATH --prepend
fi
