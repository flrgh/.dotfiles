__prompt_reset=${__prompt_reset:-""}
__prompt_alert=${__prompt_alert:-""}
__ps1_prefix=${__ps1_prefix:-"@\h \w"}

if (( DEBUG_BASHRC > 0 )); then
    __ps1_suffix='(# \#) (! \!) \$ '
else
    __ps1_suffix='\$ '
fi

__ps1_default="${__ps1_prefix} ${__ps1_suffix}"
__ps1_default_stale="${__ps1_stale_prefix} ${__ps1_suffix}"

PS1="$__ps1_default"

__prompt_cmd="\#"
declare -gi __need_prompt_reset=0
declare -gi __last_cmd_number=0

# update PS1 when a command returns a non-zero exit code
__last_status() {
    local -i ec=$?

    # we check the command counter so that we can only consider the exit code
    # from "new" commands and reset the state otherwise
    #
    # this way, pressing <enter> has the effect of clearing the prompt from the
    # last non-zero status
    local -i counter=${__prompt_cmd@P}
    local -i last_cmd=$__last_cmd_number
    __last_cmd_number=$counter

    if (( counter > last_cmd && ec != 0 )); then
        # uh oh red alert!!!!
        __need_prompt_reset=1
        PS1="${__ps1_prefix} (${__prompt_alert}${ec}${__prompt_reset}) ${__ps1_suffix}"

    elif (( __need_prompt_reset == 1 )); then
        PS1="$__ps1_default"
        __need_prompt_reset=0
    fi

    return "$ec"
}
