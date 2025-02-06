if [[ -z $__prompt_reset ]]; then
    readonly __prompt_reset=""
fi

if [[ -z $__prompt_alert ]]; then
    readonly __prompt_alert=""
fi

if [[ -z $__ps1_prefix ]]; then
    readonly __ps1_prefix='@\h \w'
fi

if (( DEBUG_BASHRC > 0 )); then
    readonly __ps1_suffix='(# \#) (! \!) \$ '
else
    readonly __ps1_suffix='\$ '
fi

readonly __ps1_default="${__ps1_prefix} ${__ps1_suffix}"
export PS1="$__ps1_default"

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

    return "$exit_code"
}

__rc_add_prompt_command "__last_status"
