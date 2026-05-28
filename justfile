image := "ghcr.io/pcrockett/allthetools"

[private]
_default:
    @just --list

# Build the image
build:
    docker compose build --pull

# Run daemon (sshd + anything else in src/start-allthetools) in background
up:
    docker compose up --wait

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

# Configure docker to push to GitHub image registry
login:
    #!/usr/bin/env bash
    set -euo pipefail
    username="$(gh auth status --json hosts --jq '.hosts["github.com"].[0].login')"
    gh auth token | docker login ghcr.io --password-stdin --username "${username}"

# Build and push ghcr.io/pcrockett/allthetools:<tag>
publish tag:
    docker build --pull --tag "{{image}}:{{tag}}" ./src
    docker push "{{image}}:{{tag}}"
