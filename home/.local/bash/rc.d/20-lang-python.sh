if [[ -f $HOME/.local/.startup.py ]]; then
    export PYTHONSTARTUP=$HOME/.local/.startup.py
fi

export IPYTHONDIR="$HOME/.config/ipython"
