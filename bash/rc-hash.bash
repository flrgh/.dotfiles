__hashfile=${XDG_STATE_HOME:?}/bashrc.md5
__loaded_hash=$(< "$__hashfile")
__loaded_at=$(( ${EPOCHREALTIME/.} / 1000 ))
__rcfile=${HOME}/.bashrc
declare -gi __rc_is_stale=0

__rehash() {
    local sum; sum=$(md5sum "$__rcfile")
    sum=${sum%% *}
    printf '%s\n' "$sum" > "$__hashfile"
    touch --reference "$__rcfile" "$__hashfile"
    __file_hash=${sum}
}

__check_rc_hash() {
    if (( __rc_is_stale )); then
        return
    fi

    if [[ -z $__loaded_hash ]]; then
        __rehash
        __loaded_at=${EPOCHSECONDS:?}
        return
    fi

    __get_mtime "$__hashfile"
    local -i hash_mtime=$(( REPLY * 1000))

    if (( hash_mtime > __loaded_at )); then
        if [[ $(< "$__hashfile") == "$__loaded_hash" ]]; then
            # the hash file was updated but didn't change
            # kinda weird but okay
            __loaded_at=$hash_mtime
        else
            echo "WARN: ~/.bashrc has changed since loading"
            __rc_is_stale=1
            __ps1_prefix=$__ps1_stale_prefix
            __ps1_default=$__ps1_default_stale
            PS1=$__ps1_default
        fi
    fi
}
