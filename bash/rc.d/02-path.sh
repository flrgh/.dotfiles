__rc_add_path --prepend PATH "$HOME/.local/bin"

__rc_add_path --prepend MANPATH "$HOME/.local/man"
__rc_add_path --prepend MANPATH "$HOME/.local/share/man"
__rc_add_path --append  MANPATH /usr/local/share/man
__rc_add_path --append  MANPATH /usr/share/man
