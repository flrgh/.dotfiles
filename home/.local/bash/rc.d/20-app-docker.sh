# https://docs.docker.com/reference/cli/docker/
export DOCKER_CONFIG=$XDG_CONFIG_HOME/docker

# OpenTelemetry (just a placeholder to remind future me to check this out)
unset DOCKER_CLI_OTEL_EXPORTER_OTLP_ENDPOINT

export DOCKER_SCOUT_CACHE_DIR=$XDG_CACHE_HOME/docker-scout
