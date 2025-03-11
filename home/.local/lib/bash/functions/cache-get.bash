cache-get() {
    local -i quiet=${CACHE_GET_QUIET:-0}
    local -i silent=${CACHE_GET_SILENT:-0}

    unset CACHE_GET_STATUS
    unset CACHE_GET_CACHED
    unset CACHE_GET_DEST

    while [[ $1 ]]; do
        arg=$1
        case $arg in
            -q|--quiet) quiet=1; shift ;;
            -s|--silent) silent=1; shift ;;
            *) break ;;
        esac
    done

    local -r url=${1?URL required}

    local fname=${2:-}
    if [[ -z $fname ]]; then
        fname=${url##*//}
        fname=${fname%\?*}
    fi

    local -r dir=$HOME/.cache/download
    mkdir -p "$dir"

    local -r dest="${dir}/${fname}"
    local -r etag=${dest}.etag

    local log=printf
    if (( quiet == 1 )); then
        log=':'
    fi

    "$log" "URL: $url\n" >&2
    "$log" "Destination: $dest\n" >&2

    "$log" "Fetching ... " >&2

    local tmp; tmp=$(mktemp)

    local -a args=(
        --silent
        --fail
        --location
        --compressed
        --referer ';auto'
        --etag-save "$etag"
        --etag-compare "$etag"
        --remote-time
        --remove-on-error
        --retry 3
        --speed-limit 1024
        --speed-time 10
        --output "$dest"
        --url "$url"
        --write-out "%output{$tmp}%{response_code}/%{size_download}"
    )

    if [[ -e $dest ]]; then
        "$log" "File is cached locally; using If-Modified-Since\n" >&2

        args+=(--time-cond "$dest")
    fi

    command curl "${args[@]}"

    "$log" "done.\n" >&2

    local res; res=$(< "$tmp")
    local -i status=${res%%/*}
    local -i bytes=${res##*/}

    "$log" "HTTP status: %s\n" "$status" >&2
    "$log" "Downloaded bytes: %s\n" "$bytes" >&2

    declare -gi CACHE_GET_STATUS=$status
    declare -gi CACHE_GET_CACHED=0

    if (( status < 200 || status > 399 )); then
        "$log" "download failed!\n" >&2
        return 2
    fi

    if (( status == 304 && bytes == 0 )); then
        "$log" "file was cached\n" >&2
        CACHE_GET_CACHED=1
    else
        "$log" "file was not cached\n" >&2
        CACHE_GET_CACHED=0
    fi

    declare -g CACHE_GET_DEST=$dest

    if (( silent == 0 )); then
        printf "%s\n" "$dest"
    fi
}
