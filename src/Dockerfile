# hadolint ignore=DL3007
FROM archlinux:latest AS base
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
#
# "unlock" account by setting a password that can't be matched
# important if we want to login via SSH
usermod -p '*' dev && \
#
# setup services script directory
mkdir --parent /opt/allthetools/services/active && \
ln --symbolic ../sshd.sh /opt/allthetools/services/active/50-sshd.sh

COPY download-artifact.sh /usr/local/bin

FROM base AS shellcheck
# shellcheck-static avoids pulling in 165 MB of GHC runtime that the Arch
# `shellcheck` package depends on.
ARG SHELLCHECK_VERSION=0.11.0
ARG SHELLCHECK_SHA=8c3be12b05d5c177a04c29e3c78ce89ac86f1595681cab149b65b97c4e227198
RUN \
download-artifact.sh \
  "https://github.com/koalaman/shellcheck/releases/download/v${SHELLCHECK_VERSION}/shellcheck-v${SHELLCHECK_VERSION}.linux.x86_64.tar.xz" \
  /tmp/shellcheck.tar.xz \
  "${SHELLCHECK_SHA}" && \
tar -xJ -C /usr/local/bin --strip-components=1 -f /tmp/shellcheck.tar.xz "shellcheck-v${SHELLCHECK_VERSION}/shellcheck" && \
rm /tmp/shellcheck.tar.xz

FROM base AS hadolint
ARG HADOLINT_VERSION=2.14.0
ARG HADOLINT_SHA=6bf226944684f56c84dd014e8b979d27425c0148f61b3bd99bcc6f39e9dc5a47
RUN \
download-artifact.sh \
  "https://github.com/hadolint/hadolint/releases/download/v${HADOLINT_VERSION}/hadolint-linux-x86_64" \
  /tmp/hadolint \
  "${HADOLINT_SHA}" && \
chmod +x /tmp/hadolint && \
mv /tmp/hadolint /usr/local/bin

FROM base

COPY --from=shellcheck /usr/local/bin/shellcheck /usr/local/bin
COPY --from=hadolint /usr/local/bin/hadolint /usr/local/bin
COPY sshd.sh /opt/allthetools/services/
COPY start-allthetools /usr/local/bin/start-allthetools

EXPOSE 22

ENV \
DIFFPROG=/usr/bin/delta \
PIP_REQUIRE_VIRTUALENV=true

WORKDIR /
CMD ["/bin/bash"]
