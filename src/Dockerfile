# hadolint ignore=DL3007
FROM archlinux:latest
SHELL ["/bin/bash", "-euo", "pipefail", "-c"]

COPY pacman-pkgs.txt /opt/pacman-pkgs.txt

RUN \
# Skip docs/man/non-English locales at install time — saves ~100 MB across
# the package set. Must be set before any pacman -S calls.
sed -i \
  -e 's|^#\?NoExtract.*|NoExtract = usr/share/man/* usr/share/doc/* usr/share/info/* usr/share/locale/* !usr/share/locale/en* !usr/share/locale/locale.alias|' \
  /etc/pacman.conf && \
#
# bootstrap local root of trust, system upgrade, and install All The Tools
pacman-key --init && \
pacman-key --populate archlinux && \
pacman --sync --refresh --sysupgrade --noconfirm --noprogressbar && \
xargs pacman --sync --needed --noconfirm --noprogressbar </opt/pacman-pkgs.txt && \
#
# clean up cache, package database, and local signing keys from `pacman-key --init`
# above. local signing keys are important to remove because theoretically they
# could be used to sign malicious packages, and downstream users of this image would
# automatically trust those packages.
rm -rf /var/cache/pacman/pkg/* /var/lib/pacman/sync/* /etc/pacman.d/gnupg && \
#
# setup unprivileged user
useradd --create-home --shell /bin/bash dev && \
# "unlock" account by setting a password that can't be matched
# important if we want to login via SSH
usermod -p '*' dev && \
mkdir -p /home/dev/.ssh && \
chown dev:dev /home/dev/.ssh && \
chmod 700 /home/dev/.ssh

# shellcheck-static avoids pulling in 165 MB of GHC runtime that the Arch
# `shellcheck` package depends on.
ARG SHELLCHECK_VERSION=0.11.0
ARG SHELLCHECK_SHA256=8c3be12b05d5c177a04c29e3c78ce89ac86f1595681cab149b65b97c4e227198
RUN \
curl -fsSL "https://github.com/koalaman/shellcheck/releases/download/v${SHELLCHECK_VERSION}/shellcheck-v${SHELLCHECK_VERSION}.linux.x86_64.tar.xz" -o /tmp/shellcheck.tar.xz && \
  echo "${SHELLCHECK_SHA256}  /tmp/shellcheck.tar.xz" | sha256sum -c - && \
  tar -xJ -C /usr/local/bin --strip-components=1 -f /tmp/shellcheck.tar.xz "shellcheck-v${SHELLCHECK_VERSION}/shellcheck" && \
  rm /tmp/shellcheck.tar.xz

COPY 99-allthetools.conf /etc/ssh/sshd_config.d/99-allthetools.conf
COPY start-allthetools /usr/local/bin/start-allthetools

# SSH port + any other ports you want exposed
EXPOSE 22

WORKDIR /
CMD ["/bin/bash"]
