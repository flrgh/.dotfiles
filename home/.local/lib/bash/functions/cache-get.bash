# set to 1 to enable --quiet
CACHE_GET_QUIET=${CACHE_GET_QUIET:-0}
declare -gi CACHE_GET_QUIET

# set to 1 to enable --silent
CACHE_GET_SILENT=${CACHE_GET_SILENT:-0}
declare -gi CACHE_GET_SILENT

# the HTTP status code of the response
CACHE_GET_STATUS=0
declare -gi CACHE_GET_STATUS

# 1 if cached, 0 otherwise
CACHE_GET_CACHED=-1
declare -gi CACHE_GET_CACHED

# path to the downloaded asset
CACHE_GET_DEST=
declare -g CACHE_GET_DEST

cache-get() {
    local -i quiet=${CACHE_GET_QUIET:-0}
    local -i silent=${CACHE_GET_SILENT:-0}

    declare -gi CACHE_GET_STATUS=0
    declare -gi CACHE_GET_CACHED=-1
    declare -g CACHE_GET_DEST=""

    local arg
    while [[ $1 ]]; do
        arg=$1
        case $arg in
            -q|--quiet) quiet=1; shift ;;
            -s|--silent) silent=1; shift ;;
            *) break ;;
        esac
    done

    local -r url=${1:?URL required}

    local basedir=$HOME/.cache/download

    local dest

    case ${2:-auto} in
        # cache-get <url>
        # cache-get <url> auto
        auto)
            local fname=$url

            # remove scheme
            fname=${fname#*'://'}

            # remove the query string and fragment
            fname=${fname%'?'*}
            fname=${fname%'#'*}

            dest=${basedir}/${fname}
            ;;

        # cache-get <url> ${HOME}/.cache/download/filename
        # cache-get <url> ${HOME}/.cache/download/path/to/filename
        "$basedir"/*)
            dest=${2}
            ;;

        # cache-get <url> /path/to/filename
        # cache-get <url> ./path/to/filename
        # cache-get <url> ../path/to/filename
        #
        # absolute or relative path => download and copy
        /|/*|.|./|./*|..|../|../*)
            echo "Invalid dest filename" >&2
            return 127
            ;;

        # cache-get <url> filename
        # cache-get <url> path/to/filename
        *)
            dest=${basedir}/${2}
            ;;
    esac

    # normalize the destination path
    dest=$(command realpath --canonicalize-missing "$dest")

    # re-check
    if [[ $dest != "$basedir"/* ]]; then
        echo "Invalid dest filename" >&2
        return 127
    fi

    local -r dest=${dest}
    local -r etag=${dest}.etag
    local -r last_url=${dest}.url

    local log=printf
    if (( quiet == 1 )); then
        log=':'
    fi

    "$log" "URL: $url\n" >&2
    "$log" "Destination: $dest\n" >&2

    mkdir -p "${dest%/*}"

    local wtmp; wtmp=$(mktemp)
    local dtmp; dtmp=$(mktemp)
    local etmp; etmp=$(mktemp)

    local -a args=(
        --silent
        --location
        --compressed
        --create-dirs
        --referer ';auto'
        --etag-save "$etmp"
        --remote-time
        --remove-on-error
        --retry 3
        --speed-limit 1024
        --speed-time 10
        --output "$dtmp"
        --url "$url"
        --write-out "%output{$wtmp}%{response_code}/%{size_download}"
    )

    if [[ -e $last_url && $(< "$last_url") != "$url" ]]; then
        "$log" "Download url has changed\n" >&2

    elif [[ -s $dest ]]; then
        "$log" "File is cached locally; using If-Modified-Since\n" >&2
        args+=(--time-cond "$dest")

        if [[ -s $etag ]]; then
            "$log" "ETag file exists; using If-None-Match\n" >&2
            args+=(--etag-compare "$etag")
        fi
    fi

    "$log" "Fetching ... " >&2

    command curl "${args[@]}" || {
        local ec=$?
        echo "error: 'curl ${args[*]}' returned ${ec}" >&2

        cat "$wtmp" || true
        head "$dtmp" || true
        rm -f "${wtmp:?}" "${dtmp:?}" "${etmp:?}"

        return 2
    }

    "$log" "done.\n" >&2

    local res; res=$(< "$wtmp")
    rm -f "${wtmp:?}"

    local -i status=${res%%/*}
    local -i bytes=${res##*/}

    "$log" "HTTP status: %s\n" "$status" >&2
    "$log" "Downloaded bytes: %s\n" "$bytes" >&2

    CACHE_GET_STATUS=$status
    CACHE_GET_CACHED=0

    if (( status == 304 && bytes == 0 )); then
        rm -f "${dtmp:?}" "${etmp:?}"

        if [[ ! -s $dest ]]; then
            echo "error: server indicated a cache hit, but we don't have a local copy ($url)" >&2
            return 2
        fi

        "$log" "file was cached\n" >&2
        CACHE_GET_CACHED=1

    else
        "$log" "file was not cached\n" >&2

        if (( status < 200 || status > 399 )); then
            echo "error: unexpected server status code $status ($url)" >&2
            rm -f "${dtmp:?}" "${etmp:?}"
            return 2
        fi

        if [[ ! -s $dtmp ]]; then
            echo "error: server returned an empty response ($url)" >&2
            rm -f "${dtmp:?}" "${etmp:?}"
            return 2
        fi

        mv "$dtmp" "$dest"

        if [[ -s $etmp ]]; then
            mv "$etmp" "$etag"
        else
            rm -f "${etmp:?}" "${etag:?}"
        fi
    fi

    # update atime
    touch -a "$dest"

    if [[ -s $etag ]]; then
        # etag file should match mtime and atime of dest file
        touch --reference "$dest" "$etag"
    fi

    echo "$url" > "$last_url"
    touch --reference "$dest" "$last_url"

    CACHE_GET_DEST=$dest

    if (( silent == 0 )); then
        echo "$dest"
    fi
}
