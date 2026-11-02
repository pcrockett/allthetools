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
useradd --create-home --shell /bin/fish dev && \
#
# "unlock" account by setting a password that can't be matched
# important if we want to login via SSH
usermod -p '*' dev && \
#
# setup services script directory
mkdir --parent /opt/allthetools/services/active && \
ln --symbolic ../sshd.sh /opt/allthetools/services/active/50-sshd.sh && \
ln --symbolic "$(command -v helix)" /usr/local/bin/hx

COPY download-artifact.sh /usr/local/bin

FROM base AS mise-tools

COPY mise.toml /root/.config/mise/config.toml
COPY mise.lock /root/.config/mise/mise.lock
RUN mise install --locked

FROM base

COPY --from=mise-tools /root/.local/share/mise/installs/shellcheck/latest/shellcheck-v*/shellcheck /usr/local/bin
COPY --from=mise-tools /root/.local/share/mise/installs/hadolint/latest/hadolint /usr/local/bin
COPY --from=mise-tools /root/.config/mise/ /root/home/.config/mise/
COPY sshd.sh /opt/allthetools/services/
COPY start-allthetools /usr/local/bin/start-allthetools
COPY --chown=dev:dev bashrc /home/dev/.bashrc
COPY --chown=dev:dev config.fish /home/dev/.config/fish/config.fish

EXPOSE 22

ENV \
DIFFPROG=/usr/bin/delta \
PIP_REQUIRE_VIRTUALENV=true

WORKDIR /
CMD ["/bin/bash"]
