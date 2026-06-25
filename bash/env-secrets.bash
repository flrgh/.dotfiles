SECRETS_ENV="${XDG_RUNTIME_DIR:?}/secrets/env"

if [[ -s $SECRETS_ENV ]]; then
    # shellcheck disable=SC1090
    source "$SECRETS_ENV"
fi
