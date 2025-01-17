# shellcheck enable=deprecate-which

__rc_source_file() {
    local -r fname=$1
    local ret

    __rc_timer_start "__rc_source_file($fname)"

    if [[ -f $fname || -h $fname ]] && [[ -r $fname ]]; then
        __rc_debug "sourcing file: $fname"

        # shellcheck disable=SC1090
        source "$fname"
        ret=$?
    else
        __rc_debug "$fname does not exist or is not a regular file"
        ret=1
    fi

    __rc_timer_stop

    return $ret
}

__rc_source_dir() {
    local dir=$1
    if ! [[ -d $dir ]]; then
        __rc_debug "$dir does not exist"
        return
    fi

    # nullglob must be set/reset outside of the file-sourcing context, or else
    # it is impossible for any sourced file to toggle its value
    local -i reset=0
    if ! shopt -q nullglob; then
        shopt -s nullglob
        reset=1
    fi

    local -a files=("$dir"/*)

    if (( reset == 1 )); then
        shopt -u nullglob
    fi

    local f
    for f in "${files[@]}"; do
        __rc_source_file "$f"
    done
}
