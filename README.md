# allthetools

A Docker image (`archlinux:latest` + my preferred CLI tooling) that runs
either as an interactive shell or as an sshd daemon supervised by tini.

See the `justfile` for targets (`just` lists them).

## Pulling

```
docker pull ghcr.io/pcrockett/allthetools:latest
```

Or as a base image:

```dockerfile
FROM ghcr.io/pcrockett/allthetools:latest
```

## Daemon

`just up` requires `SSH_AUTHORIZED_KEYS` in the environment — it's written to
`dev`'s `authorized_keys` at boot and the daemon refuses to start without it.
The provided `.envrc.example` populates it from `~/.ssh/id_ed25519.pub`.

To add more supervised services, add a script that `exec`s the service to
`/opt/allthetools/services/active`. See [the sshd script](src/sshd.sh) for an example.

## Publishing

`just publish <tag>` builds `src/Dockerfile` and pushes
`ghcr.io/pcrockett/allthetools:<tag>`. Requires `docker login ghcr.io`
beforehand; see `just login`.

## Deriving New Images

If you're building your own image based on this one, there's a `download-artifact.sh`
script to download arbitrary artifacts and validate their SHA256 checksums, for those
pesky tools that haven't made it into Arch repos yet. See `Dockerfile` for example
usage.
