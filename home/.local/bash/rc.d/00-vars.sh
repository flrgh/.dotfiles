# clean slate
unset PROMPT_COMMAND

if [[ -f ~/.config/env ]]; then
    source "$HOME"/.config/env
fi
