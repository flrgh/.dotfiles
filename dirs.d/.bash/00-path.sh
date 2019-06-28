paths=(
    "$HOME/.local/bin"
)

for p in "${paths[@]}"; do
    if ! [[ $PATH =~ :?$p:? ]]; then
        export PATH=${p}:$PATH
    fi
done
