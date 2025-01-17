#!/usr/bin/env bash

source "$REPO_ROOT"/lib/bash/generate.bash

source "$BASH_USER_LIB"/ansi.bash

bashrc-declare() {
    bashrc-pref 'prompt_vars' 'declare %s %s=%q\n' "$@"
}

_args=(--prompt --reset)

_cyan=; ansi-style "${_args[@]}" -v _cyan  --cyan
_blue=; ansi-style "${_args[@]}" -v _blue  --blue

__prompt_alert=; ansi-style "${_args[@]}" -v __prompt_alert --bold --color bright-red
__prompt_reset=; ansi-style "${_args[@]}" -v __prompt_reset

bashrc-declare -gr __prompt_alert "$__prompt_alert"
bashrc-declare -gr __prompt_reset "$__prompt_reset"

_prompt_host='\h'
_prompt_pwd='\w'
_prompt_user_at_host="${_cyan}@${_prompt_host}${__prompt_reset}"
_prompt_pwd="${_blue}${_prompt_pwd}${__prompt_reset}"

bashrc-declare -gr __ps1_prefix "${_prompt_user_at_host} ${_prompt_pwd}"
