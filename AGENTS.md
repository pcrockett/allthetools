# AGENTS.md

This file provides guidance to AI agents when working with code in this repository.

## Purpose

This repo builds a single Docker image (`allthetools`) that bundles my preferred
CLI tooling on top of `archlinux:latest`. There is no application code — just
the `src/Dockerfile`, a `compose.yml`, a `justfile`, and the supporting bits in
`src/`.

The image is used two ways:

1. **As a long-running daemon** that exposes sshd (and optionally other
   services) supervised by tini. Brought up via `docker compose` from
   `compose.yml`.
2. **As an interactive shell** for ad-hoc commands, with the cwd mounted at
   `/workspace`.

## Build & run

- `just up` — start the daemon in the background (sshd, plus anything else
  listed in `src/start-allthetools`)
- `just down` — tear the daemon down
- `just logs` — follow daemon logs
- `just shell` — root shell inside a one-shot container
- `just run [args...]` — interactive shell as the `dev` user with the cwd
  mounted at `/workspace`
- `just ssh` — `ssh` into the running daemon on `127.0.0.1:${SSH_PORT:-2222}`
- `just publish <tag>` — build and push `ghcr.io/pcrockett/allthetools:<tag>`

The daemon requires `SSH_AUTHORIZED_KEYS` in the environment before `just up`;
the start script writes the contents to `/home/dev/.ssh/authorized_keys` at
boot and refuses to start if it's unset. `direnv` (via `.envrc.example`)
populates this from `~/.ssh/id_ed25519.pub` by default.

## Conventions

- **Prefer official Arch packages (`pacman -S`) over every other install
  method.** Only fall back to AUR, `curl | sh`, language package managers, or
  upstream tarballs when no Arch package exists. If you must, note the reason
  inline in the Dockerfile.
- Keep package installs as a single `pacman -S --noconfirm --needed
  </opt/pacman-pkgs.txt` invocation inside one `RUN` layer, followed by
  `pacman -Sc --noconfirm` to drop the cache. Don't split installs across
  layers. Add new tools to `src/pacman-pkgs.txt`, one per line, sorted.
- The Dockerfile sets no `USER`, so the image defaults to root. The daemon
  needs root for sshd (compose pins `user: "0:0"`). Interactive shells drop
  to `dev` via `--user dev` in the `just run` recipe. SSH logins always land
  as `dev` regardless. No `sudo` is installed — the container is not meant
  for in-place package installs at runtime.
- Override sshd config via the `/etc/ssh/sshd_config.d/99-allthetools.conf`
  drop-in, not by replacing the full `sshd_config`. Keeps the surface small
  when upstream sshd defaults change.
- Additional supervised services are added by editing the `services` section
  of `src/start-allthetools` (append `start <command...>` lines), not by
  passing arguments at runtime. If any supervised process exits, the whole
  container shuts down so tini can exit cleanly.
- The Docker socket can be mounted at runtime, never baked in. The `docker`
  package is installed for its CLI only; no daemon runs inside the container.
