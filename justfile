image := "ghcr.io/pcrockett/allthetools"

[private]
_default:
    @just --list

# Build the image
build:
    docker compose build

# Run daemon (sshd + anything else in src/start-allthetools) in background
up:
    docker compose up --build --pull always --wait

# Stop daemon
down:
    docker compose down

# Follow daemon logs
logs:
    docker compose logs --follow

# Run pre-commit on all files
lint:
    pre-commit run --all --show-diff-on-failure --color always

# Root shell inside a one-shot container (build context)
shell:
    docker compose run --rm --interactive dev bash

# Interactive shell as `dev` with the cwd mounted at /workspace
run *args:
    docker compose run \
        --rm \
        --interactive \
        --tty \
        --user dev \
        --workdir /workspace \
        --volume "$PWD":/workspace \
        --no-deps \
        --entrypoint "" \
        dev bash {{args}}

# SSH into the running daemon
ssh:
    #!/usr/bin/env bash
    set -euo pipefail
    ssh \
        -p "${SSH_PORT:-2222}" \
        -o NoHostAuthenticationForLocalhost=yes \
        "dev@${SSH_HOST:-127.0.0.1}"

# Build and push ghcr.io/pcrockett/allthetools:<tag> (requires `docker login ghcr.io`)
publish tag:
    docker build --tag "{{image}}:{{tag}}" ./src
    docker push "{{image}}:{{tag}}"
