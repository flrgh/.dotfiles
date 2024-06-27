__rc_add_path "$HOME/.local/bin" --prepend

__rc_add_path "$HOME/.local/man"       MANPATH --prepend
__rc_add_path "$HOME/.local/share/man" MANPATH --prepend
__rc_add_path /usr/local/share/man     MANPATH --append
__rc_add_path /usr/share/man           MANPATH --append
