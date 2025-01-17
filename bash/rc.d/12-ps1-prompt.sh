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

if [[ -z $__prompt_reset || -z $__prompt_alert || -z $__ps1_prefix ]]; then
    __rc_source_file "$BASH_USER_LIB"/ansi.bash

    # _single_underscore vars are temp
    # __double_underscore vars are persistent

    _args=(--prompt --reset)
    _prompt_host='\h'
    _prompt_pwd='\w'

    _cyan=;  ansi-style "${_args[@]}" -v _cyan  --cyan
    _blue=;  ansi-style "${_args[@]}" -v _blue  --blue

    __prompt_alert=; ansi-style "${_args[@]}" -v __prompt_alert --bold --color bright-red
    __prompt_reset=; ansi-style "${_args[@]}" -v __prompt_reset

    readonly __prompt_alert __prompt_reset

    _prompt_user_at_host="${_cyan}@${_prompt_host}${__prompt_reset}"
    _prompt_pwd="${_blue}${_prompt_pwd}${__prompt_reset}"

    readonly __ps1_prefix="${_prompt_user_at_host} ${_prompt_pwd}"
fi

if (( DEBUG_BASHRC > 0 )); then
    readonly __ps1_suffix='(# \#) (! \!) \$ '
else
    readonly __ps1_suffix='\$ '
fi
readonly __ps1_default="${__ps1_prefix} ${__ps1_suffix}"
export PS1="$__ps1_default"

unset _args _prompt_host _prompt_pwd _prompt_user_at_host _prompt_pwd _cyan _blue || true

readonly __prompt_cmd="\#"
declare -gi __need_prompt_reset=0
declare -gi __last_cmd_number=0

# update PS1 when a command returns a non-zero exit code
__last_status() {
    local -i exit_code=$?

    # we check the command counter so that we can only consider the exit code
    # from "new" commands and reset the state otherwise
    #
    # this way, pressing <enter> has the effect of clearing the prompt from the
    # last non-zero status
    local -i counter=${__prompt_cmd@P}
    local -i last_cmd=$__last_cmd_number
    __last_cmd_number=$counter

    if (( counter > last_cmd && exit_code != 0 )); then
        # uh oh red alert!!!!
        __need_prompt_reset=1
        export PS1="${__ps1_prefix} (${__prompt_alert}${exit_code}${__prompt_reset}) ${__ps1_suffix}"

    elif (( __need_prompt_reset == 1 )); then
        export PS1="$__ps1_default"
        __need_prompt_reset=0
    fi
}

__rc_add_prompt_command "__last_status"
