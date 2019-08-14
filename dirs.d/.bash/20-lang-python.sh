PYTHONSTARTUP=$HOME/.local/.startup.py
if [[ -f $PYTHONSTARTUP ]]; then
    export PYTHONSTARTUP
fi

export IPYTHONDIR="$HOME/.config/ipython"
