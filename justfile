[private]
_default:
    @just --list

# Run container in background
up:
    docker compose up --build --pull always --wait

# Stop container
down:
    docker compose down

# Follow container logs
logs:
    docker compose logs --follow

# Run pre-commit on all files
lint:
    pre-commit run --all --show-diff-on-failure --color always

# Run a shell inside the container as root
shell:
    docker compose run --rm --interactive dev bash

# SSH into the container
ssh:
    #!/usr/bin/env bash
    set -euo pipefail
    ssh \
        -p "${SSH_PORT:-2222}" \
        -o NoHostAuthenticationForLocalhost=yes \
        "dev@${SSH_HOST:-127.0.0.1}"
