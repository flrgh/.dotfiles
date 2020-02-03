export XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME/.config}
export CONFIG_HOME=$XDG_CONFIG_HOME

mkdir -p "$HOME/.cache"
export CACHE_DIR="$HOME/.cache"
