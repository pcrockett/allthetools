#!/usr/bin/env bash
set -euo pipefail

# inspired by <https://sirikon.me/posts/0009-pid-1-bash-script-docker-container.html>
# see article for full line-by-line explanation

start_daemons() {
  /usr/bin/sshd -e -D &
}

ssh_init() {
  ssh-keygen -A -t ed25519 2>/dev/null

  if [ -n "${SSH_AUTHORIZED_KEYS:-}" ]; then
    printf '%s\n' "$SSH_AUTHORIZED_KEYS" >/home/dev/.ssh/authorized_keys
    chown dev:dev /home/dev/.ssh/authorized_keys
    chmod 600 /home/dev/.ssh/authorized_keys
    echo "SSH authorized keys installed for dev user"
  fi

  mkdir -p /run/sshd
}

shutdown() {
  pkill -SIGTERM --pgroup $$

  # wait 3 seconds, and if background jobs are still running, escalate to SIGKILL.
  for _ in $(seq 1 30); do
    if [ "$(jobs -p 2>/dev/null | wc -l)" -eq 0 ]; then
      return
    else
      sleep 0.1
    fi
  done
  echo "Background jobs still running; sending SIGKILL."
  pkill -SIGKILL --pgroup $$
}

main() {
  ssh_init
  start_daemons

  echo "COMMAND: \`$*\`"

  local exit_code=0
  if [ "$*" == "" ]; then
    # tell bash to pay attention to SIGINT and SIGTERM signals while waiting. we don't
    # need to execute anything in our trap because any signal will unblock our following
    # `wait` call anyway.
    trap 'true' SIGINT SIGTERM
    wait -n || exit_code=$?
    echo "Process exited or signal received; shutting down..."
  else
    "$@" || exit_code=$?
  fi

  shutdown
  wait || true
  exit ${exit_code}
}

main "$@"
