# General shell options

# globbing should get files/directories that start with .
shopt -s dotglob

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# don't search $PATH when sourcing a filename
shopt -u sourcepath

# make less more friendly for non-text input files, see lesspipe(1)
if [[ -x /usr/bin/lesspipe ]]; then
    eval "$(SHELL=/bin/sh lesspipe)"
fi

# use bat as a man pager if it exists
if __rc_command_exists bat; then
    export MANPAGER="sh -c 'col -bx | bat -l man -p'"
    export MANROFFOPT="-c"
fi

# I hate this thing
if __rc_command_exists command_not_found_handle; then
    __rc_debug "unsetting command_not_found_handle func"
    unset -f command_not_found_handle
fi

# When  executing  interactively, bash displays the primary prompt PS1 when it is
# ready to read a command, and the secondary prompt PS2 when it needs more input
# to complete a command.  Bash displays PS0 after it reads a command but before
# executing it.  Bash displays PS4 as described above before tracing each command
# when the -x option is enabled.  Bash allows these prompt strings to be customized
# by inserting a number of backslash-escaped special characters that are decoded as
# follows:
#
#  \a     an ASCII bell character (07)
#  \d     the date in "Weekday Month Date" format (e.g., "Tue May 26")
#  \D{format}
#         the format is passed to strftime(3) and the result is inserted into the
#         prompt string; an empty format results in a locale-specific time
#         representation.  The braces are required
#  \e     an ASCII escape character (033)
#  \h     the hostname up to the first `.'
#  \H     the hostname
#  \j     the number of jobs currently managed by the shell
#  \l     the basename of the shell's terminal device name
#  \n     newline
#  \r     carriage return
#  \s     the name of the shell, the basename of $0 (the portion following the final slash)
#  \t     the current time in 24-hour HH:MM:SS format
#  \T     the current time in 12-hour HH:MM:SS format
#  \@     the current time in 12-hour am/pm format
#  \A     the current time in 24-hour HH:MM format
#  \u     the username of the current user
#  \v     the version of bash (e.g., 2.00)
#  \V     the release of bash, version + patch level (e.g., 2.00.0)
#  \w     the value of the PWD shell variable ($PWD), with $HOME abbreviated with
#         a tilde (uses the value of the PROMPT_DIRTRIM variable)
#  \W     the basename of $PWD, with $HOME abbreviated with a tilde
#  \!     the history number of this command
#  \#     the command number of this command
#  \$     if the effective UID is 0, a #, otherwise a $
#  \nnn   the character corresponding to the octal number nnn
#  \\     a backslash
#  \[     begin a sequence of non-printing characters, which could be used to
#         embed a terminal control sequence into the prompt
#  \]     end a sequence of non-printing characters

source "$BASH_USER_LIB"/ansi.bash

__args=(--prompt --reset)

__cyan=;  ansi-style "${__args[@]}" -v __cyan  --cyan
__blue=;  ansi-style "${__args[@]}" -v __blue  --blue
__alert=; ansi-style "${__args[@]}" -v __alert --bold --color bright-red
__reset=; ansi-style "${__args[@]}" -v __reset

__host='\h'
_PS1_USER_AT_HOST="${__cyan}@${__host}${__reset}"

__pwd='\w'
_PS1_PWD="${__blue}${__pwd}${__reset}"

__prompt="\\$"
__ps1_base="${_PS1_USER_AT_HOST} ${_PS1_PWD}"
__ps1_default="${__ps1_base} ${__prompt} "

__reset_prompt() {
    export PS1="$__ps1_default"
}

__reset_prompt

__append_prompt() {
    local -r extra="${1:-}"

    export PS1="${__ps1_base} ${extra} ${__prompt} "
}

__need_reset=0

__last_status() {
    local ec=$?

    if (( ec != 0 )); then
        # uh oh red alert!!!!
        __need_reset=1
        __append_prompt "(${__alert}${ec}${__reset})"
        return
    fi

    if (( __need_reset == 0 )); then
        return
    fi

    # back to happy times
    __reset_prompt
    __need_reset=0
}

__rc_add_prompt_command "__last_status"
