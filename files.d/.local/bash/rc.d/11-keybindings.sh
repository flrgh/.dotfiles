# Use readline backward-kill-word instead of tty werase
# I prefer this because backward-kill-word uses whitespace and the forward slash ("/") for word boundaries
if [[ $- == *i* ]]; then
    stty werase undef
    bind "\C-w: backward-kill-word"
fi
