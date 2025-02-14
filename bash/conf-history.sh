# Bash History configuration

# turn off history expansion with !
set +H

# append to the history file, don't overwrite it
shopt -s histappend

# save multi-command one-liners as a single history item
shopt -s cmdhist

# * ignorespace => don't save commmands that start with a space
# * ignoredups  => don't save commands that match the most recent entry
export HISTCONTROL=ignorespace:ignoredups
#
# Don't save history commands
export HISTIGNORE='history:history *'

# History is valuable; let's keep lots of it
#
# Every time HISTFILESIZE is set, bash opens the history file and truncates it
# to the desired size, which slows down ~/.bashrc. This conditional makes it so
# that we don't perform that extra I/O on each shell init if the value doesn't
# need to be changed.
if (( HISTFILESIZE != 100000 )); then
    export HISTFILESIZE=100000
fi
export HISTSIZE=5000

# timestamps with history
export HISTTIMEFORMAT='%F %T '

export HISTFILE=$XDG_STATE_HOME/.bash_history
