[private]
_default:
    @just --list

# Run pre-commit on all files
[group("ci")]
lint:
    pre-commit run --all --show-diff-on-failure --color always

# Build the image
[group("docker")]
build:
    docker compose build --pull

# Run daemon (sshd + anything else in src/start-allthetools) in background
[group("docker")]
up:
    docker compose up --wait

# Stop daemon
[group("docker")]
down:
    docker compose down

# Follow daemon logs
[group("docker")]
logs:
    docker compose logs --follow

# Root shell inside a one-shot container (build context)
[group("run")]
shell:
    docker compose run --rm --interactive dev bash

# Interactive shell as `dev` with the cwd mounted at /workspace
[group("run")]
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
[group("run")]
ssh:
    #!/usr/bin/env bash
    set -euo pipefail
    ssh \
        -p "${SSH_PORT:-2222}" \
        -o NoHostAuthenticationForLocalhost=yes \
        "dev@${SSH_HOST:-127.0.0.1}"

# Build and push ghcr.io/pcrockett/allthetools:<tag>
[group("release")]
publish:
    gh workflow run publish.yml

# Update the mise deps inside the Dockerfile
[group("deps")]
update-mise:
    cd src && mise up --no-global
