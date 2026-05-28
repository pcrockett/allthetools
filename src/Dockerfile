# hadolint ignore=DL3007
FROM archlinux:latest

SHELL ["/bin/bash", "-euo", "pipefail", "-c"]

# Skip docs/man/non-English locales at install time — saves ~100 MB across
# the package set. Must be set before any pacman -S calls.
RUN sed -i \
    -e 's|^#\?NoExtract.*|NoExtract = usr/share/man/* usr/share/doc/* usr/share/info/* usr/share/locale/* !usr/share/locale/en* !usr/share/locale/locale.alias|' \
    /etc/pacman.conf

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
# `pacman -Scc --noconfirm` answers "no" to the destructive "remove all
# cached packages?" prompt — pacman's safety hatch ignores --noconfirm here.
# Wipe the cache directly; saves ~330 MB.
rm -rf /var/cache/pacman/pkg/*

# shellcheck-static avoids pulling in 165 MB of GHC runtime that the Arch
# `shellcheck` package depends on.
ARG SHELLCHECK_VERSION=0.11.0
ARG SHELLCHECK_SHA256=8c3be12b05d5c177a04c29e3c78ce89ac86f1595681cab149b65b97c4e227198
RUN curl -fsSL "https://github.com/koalaman/shellcheck/releases/download/v${SHELLCHECK_VERSION}/shellcheck-v${SHELLCHECK_VERSION}.linux.x86_64.tar.xz" -o /tmp/shellcheck.tar.xz && \
    echo "${SHELLCHECK_SHA256}  /tmp/shellcheck.tar.xz" | sha256sum -c - && \
    tar -xJ -C /usr/local/bin --strip-components=1 -f /tmp/shellcheck.tar.xz "shellcheck-v${SHELLCHECK_VERSION}/shellcheck" && \
    rm /tmp/shellcheck.tar.xz

RUN \
useradd --create-home --shell /bin/bash dev && \
# "unlock" account by setting a password that can't be matched
# important if we want to login via SSH
usermod -p '*' dev && \
mkdir -p /home/dev/.ssh && \
chown dev:dev /home/dev/.ssh && \
chmod 700 /home/dev/.ssh

COPY 99-allthetools.conf /etc/ssh/sshd_config.d/99-allthetools.conf
COPY start-allthetools /usr/local/bin/start-allthetools

# SSH port + any other ports you want exposed
EXPOSE 22

WORKDIR /
CMD ["/bin/bash"]
