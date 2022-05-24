# options for fzf
if iHave fzf; then
    export FZF_DEFAULT_OPTS="--info=default --height=80% --border=sharp --tabstop=4"

    if iHave fd; then
        export FZF_DEFAULT_COMMAND='fd --hidden --type f --color=never'
        export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

        _fzf_compgen_path() {
            fd --hidden --follow --exclude ".git" . "$1"
        }

        _fzf_compgen_dir() {
            fd --type d --hidden --follow --exclude ".git" . "$1"
        }

        #export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
        #export FZF_ALT_C_COMMAND='fd --type d . --color=never'
    fi

    if [[ -f /usr/share/fzf/shell/key-bindings.bash ]]; then
        _source_file /usr/share/fzf/shell/key-bindings.bash
    fi
fi


# I have `find /some/path` permanently stored in muscle memory. This is an
# issue as I try using fd as a replacement, because the same invocation yields
# a "you're doing it wrong!" error:
#
#
# > [fd error]: The search pattern './' contains a path-separation character ('/') and will not lead to any search results.
# >
# > If you want to search for all files inside the './' directory, use a match-all pattern:
# >
# >  fd . './'
# >
# > If nstead, if you want your pattern to match the full file path, use:
# >
# >  fd --full-path './'
#
#
# This little function exists to handle that case so that I don't have to
# relearn anything
#
if iHave fd; then
    fd() {
        if (( $# == 1 )) && [[ $1 != . ]]; then
            command fd . "$1"
        else
            command fd "$@"
        fi
    }
fi
