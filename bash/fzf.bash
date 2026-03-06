declare -g __fzf_defaults__

# shellcheck disable=SC2206
__fzf_defaults() {
    declare -g __fzf_defaults__=""

    local -a opts=(
        "--height=${FZF_TMUX_HEIGHT:-40%}"
        "--min-height=20+"
        "--bind=ctrl-z:ignore"
    )

    local arg
    while (($#)); do
        arg=$1
        shift

        case $arg in
            --) break ;;
            '') continue ;;
            *) opts+=("$arg") ;;
        esac
    done

    if [[ -n ${FZF_DEFAULT_OPTS_FILE:-} && -f ${FZF_DEFAULT_OPTS_FILE} ]]; then
        local -r -i offset=$((${#opts[@]} + 1))
        builtin mapfile -t \
            -O "$offset" \
            opts \
            <"$FZF_DEFAULT_OPTS_FILE"
    fi

    if [[ -n ${FZF_DEFAULT_OPTS:-} ]]; then
        opts+=($FZF_DEFAULT_OPTS)
    fi

    while (($#)); do
        arg=$1
        shift

        case $arg in
            '') continue ;;
            *) opts+=("$arg") ;;
        esac
    done

    printf -v __fzf_defaults__ "%s" "${opts[*]}"
}

__fzf_select__() {
    __fzf_defaults \
        --reverse \
        --walker=file,dir,follow,hidden \
        --scheme=path \
        -- \
        "${FZF_CTRL_T_OPTS-}" \
        -m

    FZF_DEFAULT_COMMAND=${FZF_CTRL_T_COMMAND:-} \
        FZF_DEFAULT_OPTS="$__fzf_defaults__" \
        FZF_DEFAULT_OPTS_FILE='' \
        fzf "$@" \
    | while read -r item; do
        printf '%q ' "$item" # escape special chars
    done
}

fzf-file-widget() {
    local selected="$(__fzf_select__ "$@")"
    READLINE_LINE="${READLINE_LINE:0:READLINE_POINT}$selected${READLINE_LINE:READLINE_POINT}"
    READLINE_POINT=$((READLINE_POINT + ${#selected}))
}

declare -g __fzf_lua_history=${HOME}/.local/libexec/fzf-lua-history

__fzf_history__() {
    # TODO: replace this with new command substitution
    local len
    len=$(HISTTIMEFORMAT='' builtin history 1)
    local -i n=${len%% *}

    __fzf_defaults \
        -- \
        -n2..,.. \
        --scheme=history \
        --bind=ctrl-r:toggle-sort,alt-r:toggle-raw \
        --wrap-sign "'"$'\t'"↳ '" \
        --highlight-line \
        "${FZF_CTRL_R_OPTS-}" \
        +m \
        --read0

    local output
    output=$(
        set +o pipefail
        builtin fc -lnr -2147483648 2>/dev/null \
            | "$__fzf_lua_history" "$n" \
            | FZF_DEFAULT_OPTS="$__fzf_defaults__" \
                FZF_DEFAULT_OPTS_FILE='' \
                fzf --query "$READLINE_LINE"
    ) || return

    READLINE_LINE=${output#*$'\t'}
    if [[ -z $READLINE_POINT ]]; then
        echo "$READLINE_LINE"
    else
        READLINE_POINT=0x7fffffff
    fi
}

# Required to refresh the prompt after fzf
bind -m emacs-standard '"\C-\e(": redraw-current-line'

bind -m vi-command '"\C-z": emacs-editing-mode'
bind -m vi-insert '"\C-z": emacs-editing-mode'
bind -m emacs-standard '"\C-z": vi-editing-mode'

# CTRL-T - Paste the selected file path into the command line
bind -m emacs-standard -x '"\C-t": fzf-file-widget'
bind -m vi-command -x '"\C-t": fzf-file-widget'
bind -m vi-insert -x '"\C-t": fzf-file-widget'

# CTRL-R - Paste the selected command from history into the command line
bind -m emacs-standard -x '"\C-r": __fzf_history__'
bind -m vi-command -x '"\C-r": __fzf_history__'
bind -m vi-insert -x '"\C-r": __fzf_history__'
