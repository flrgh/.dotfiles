#!/usr/bin/env bash

source "$REPO_ROOT"/lib/bash/generate.bash

source "$BASH_USER_LIB"/ansi.bash

_args=(--prompt --reset)

_cyan=; ansi-style "${_args[@]}" -v _cyan  --cyan
_blue=; ansi-style "${_args[@]}" -v _blue  --blue

__prompt_alert=; ansi-style "${_args[@]}" -v __prompt_alert --bold --color bright-red
__prompt_reset=; ansi-style "${_args[@]}" -v __prompt_reset

bashrc-pre-declare __prompt_alert
bashrc-pre-declare __prompt_reset

_prompt_host='\h'
_prompt_pwd='\w'
_prompt_user_at_host="${_cyan}@${_prompt_host}${__prompt_reset}"
_prompt_pwd="${_blue}${_prompt_pwd}${__prompt_reset}"

__ps1_prefix="${_prompt_user_at_host} ${_prompt_pwd}"
bashrc-pre-declare __ps1_prefix
