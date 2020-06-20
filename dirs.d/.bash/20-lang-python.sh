set_python_vars() {
    if [[ -f $HOME/.local/.startup.py ]]; then
        export PYTHONSTARTUP=$HOME/.local/.startup.py
    fi

    export IPYTHONDIR="$HOME/.config/ipython"

    unset -f set_python_vars
}

set_python_vars
