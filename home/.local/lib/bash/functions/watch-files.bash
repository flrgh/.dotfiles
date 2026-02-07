watch-files() {
    inotifywait \
        --recursive \
        --monitor \
        --no-dereference \
        --timefmt '%F %T %Z' \
        --format '[%T] %e %w %f' \
        "$@"
}
