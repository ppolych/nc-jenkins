#!/usr/bin/env bash
set -euo pipefail

# --- Align 'docker' group with the host's docker socket group ---
# If /var/run/docker.sock is mounted, adjust the 'docker' group GID to match the socket's.
if [ -S /var/run/docker.sock ]; then
  sock_gid="$(stat -c %g /var/run/docker.sock || true)"
  if [ -n "${sock_gid}" ] && [ "${sock_gid}" != "0" ]; then
    # Create or modify 'docker' group to match the socket's GID
    if getent group docker >/dev/null; then
      current_gid="$(getent group docker | cut -d: -f3)"
      if [ "${current_gid}" != "${sock_gid}" ]; then
        groupmod -g "${sock_gid}" docker || true
      fi
    else
      groupadd -g "${sock_gid}" docker || true
    fi

    # Ensure jenkins is in docker group
    usermod -aG docker jenkins || true
  fi
fi

# --- Fix ownership of JENKINS_HOME just in case ---
if [ -n "${JENKINS_HOME:-}" ]; then
  mkdir -p "${JENKINS_HOME}"
  chown -R jenkins:jenkins "${JENKINS_HOME}"
fi

# --- Exec as 'jenkins' user using gosu ---
exec gosu jenkins:jenkins "$@"
