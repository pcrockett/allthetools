# hadolint ignore=DL3007
FROM archlinux:latest

# Initialize the pacman keyring and update it before installing anything.
# This must be done BEFORE any pacman -Syu or -S calls.
RUN \
pacman-key --init && \
pacman-key --populate archlinux && \
pacman -Sy --noconfirm archlinux-keyring

COPY pacman-pkgs.txt /opt/pacman-pkgs.txt
RUN \
pacman -Su --noconfirm && \
xargs pacman -S --noconfirm --needed </opt/pacman-pkgs.txt && \
# Clean pacman cache to reduce image size
pacman -Sc --noconfirm

RUN \
useradd --create-home --shell /bin/bash dev && \
# "unlock" account by setting a password that can't be matched
# important if we want to login via SSH
usermod -p '*' dev && \
mkdir -p /home/dev/.ssh && \
chown dev:dev /home/dev/.ssh && \
chmod 700 /home/dev/.ssh

COPY sshd_config /etc/ssh/sshd_config
COPY entrypoint.sh /entrypoint.sh

# SSH port + any other ports you want exposed
EXPOSE 22

ENTRYPOINT ["/entrypoint.sh"]
CMD []
