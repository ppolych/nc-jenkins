#!/usr/bin/env bash
set -euo pipefail

# Align 'docker' group with host socket GID
if [ -S /var/run/docker.sock ]; then
  sock_gid="$(stat -c %g /var/run/docker.sock || true)"
  if [ -n "${sock_gid}" ] && [ "${sock_gid}" != "0" ]; then
    if getent group docker >/dev/null; then
      current_gid="$(getent group docker | cut -d: -f3)"
      if [ "${current_gid}" != "${sock_gid}" ]; then
        groupmod -g "${sock_gid}" docker || true
      fi
    else
      groupadd -g "${sock_gid}" docker || true
    fi
    usermod -aG docker jenkins || true
  fi
fi

# Ensure JENKINS_HOME perms
if [ -n "${JENKINS_HOME:-}" ]; then
  mkdir -p "${JENKINS_HOME}"
  chown -R jenkins:jenkins "${JENKINS_HOME}"
fi

# Drop privileges to 'jenkins'
exec gosu jenkins:jenkins "$@"
