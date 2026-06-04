image := "ghcr.io/pcrockett/allthetools"

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

# Update hadolint version and checksum in Dockerfile
[group("deps")]
update-hadolint:
    #!/usr/bin/env bash
    set -euo pipefail
    latest_release="$(
        gh release view \
            --repo hadolint/hadolint \
            --json assets,tagName \
            --jq '
                {
                    tagName: .tagName,
                    asset: .assets.[] | select(.name == "hadolint-linux-x86_64")
                }
            '
    )"
    version="$(echo "${latest_release}" | jq --raw-output '.tagName')"
    sha="$(echo "${latest_release}" | jq --raw-output '.asset.digest' | cut -d: -f2)"
    sed --in-place "s/^ARG HADOLINT_VERSION=.*$/ARG HADOLINT_VERSION=${version}/" src/Dockerfile
    sed --in-place "s/^ARG HADOLINT_SHA=.*$/ARG HADOLINT_SHA=${sha}/" src/Dockerfile

# Update shellcheck version and checksum in Dockerfile
[group("deps")]
update-shellcheck:
    #!/usr/bin/env bash
    set -euo pipefail
    latest_release="$(
        gh release view \
            --repo koalaman/shellcheck \
            --json assets,tagName \
            --jq '
                {
                    tagName: .tagName,
                    asset: .assets.[] | select(.name | test("linux.x86_64.tar.xz$"))
                }
            '
    )"
    version="$(echo "${latest_release}" | jq --raw-output '.tagName')"
    sha="$(echo "${latest_release}" | jq --raw-output '.asset.digest' | cut -d: -f2)"
    sed --in-place "s/^ARG SHELLCHECK_VERSION=.*$/ARG SHELLCHECK_VERSION=${version}/" src/Dockerfile
    sed --in-place "s/^ARG SHELLCHECK_SHA=.*$/ARG SHELLCHECK_SHA=${sha}/" src/Dockerfile
