#!/usr/bin/env bash
set -euo pipefail

if [ -z "${SSH_AUTHORIZED_KEYS:-}" ]; then
  echo "SSH_AUTHORIZED_KEYS env var is required" >&2
  exit 1
fi

SERVER_CONFIG="$(
  cat <<EOF
# Authentication
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes

# Access control
AllowUsers dev

# Cosmetics
PrintMotd no
EOF
)"

echo "${SERVER_CONFIG}" >/etc/ssh/sshd_config.d/99-allthetools.conf

ssh-keygen -A

install -d -o dev -g dev -m 700 /home/dev/.ssh
printf '%s\n' "$SSH_AUTHORIZED_KEYS" >/home/dev/.ssh/authorized_keys
chown dev:dev /home/dev/.ssh/authorized_keys
chmod 600 /home/dev/.ssh/authorized_keys

mkdir --parent /run/sshd

exec /usr/bin/sshd -D -e
