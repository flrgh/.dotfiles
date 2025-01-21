dump-array() {
    local -r name=$1
    local -rn ref=$1

    local i
    local -i width=32
    local key len

    for i in "${!ref[@]}"; do
        key="${name}[$i]"
        len=${#key}
        width=$(( len > width ? len : width ))
    done

    local fmt="%-${width}s => %s\n"
    for i in "${!ref[@]}"; do
        printf "$fmt" \
                "${name}[$i]" \
                "${ref[$i]}"
    done
}
