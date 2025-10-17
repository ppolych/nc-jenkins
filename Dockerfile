# Base: Debian 13.1 (Trixie) slim
FROM debian:13.1-slim

# -----------------------------
# System setup
# -----------------------------
# Install tools, Java 21, Docker CLI, docker-compose plugin, gosu, tini, and deps
# Notes:
# - We only need the Docker CLI inside the container; the daemon comes from the host via /var/run/docker.sock.
# - gosu + tini for clean privilege drop and signal handling.
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
      ca-certificates curl gnupg git \
      openjdk-21-jdk \
      docker.io docker-compose-plugin \
      gosu tini \
    ; \
    rm -rf /var/lib/apt/lists/*

# -----------------------------
# Jenkins installation (LTS)
# -----------------------------
# Add Jenkins stable repo and key, then install Jenkins package.
RUN set -eux; \
    curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | gpg --dearmor -o /usr/share/keyrings/jenkins.gpg; \
    echo "deb [signed-by=/usr/share/keyrings/jenkins.gpg] https://pkg.jenkins.io/debian-stable binary/" > /etc/apt/sources.list.d/jenkins.list; \
    apt-get update; \
    apt-get install -y --no-install-recommends jenkins; \
    rm -rf /var/lib/apt/lists/*

# -----------------------------
# Users & groups
# -----------------------------
# Jenkins package creates user 'jenkins'. Ensure a 'docker' group exists and add jenkins to it.
# At runtime we will align the docker group's GID with the host's /var/run/docker.sock GID.
RUN set -eux; \
    if ! getent group docker >/dev/null; then groupadd -r docker; fi; \
    usermod -aG docker jenkins

# Jenkins home
ENV JENKINS_HOME=/var/jenkins_home
RUN mkdir -p "$JENKINS_HOME" && chown -R jenkins:jenkins "$JENKINS_HOME"

# -----------------------------
# Entrypoint script
# -----------------------------
# This script:
# 1) Detects the GID of /var/run/docker.sock (host) and aligns the 'docker' group inside the container.
# 2) Ensures 'jenkins' is in that docker group.
# 3) Drops privileges to 'jenkins' and starts Jenkins with tini for clean signals.
ADD docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# -----------------------------
# Networking
# -----------------------------
# EXPOSE Jenkins ports and the requested range 8200-8220 (for flexibility).
# Jenkins web: 8080, agents: 50000
EXPOSE 8080
EXPOSE 50000
EXPOSE 8200-8220

# Use tini as PID 1 and our entrypoint
ENTRYPOINT ["/usr/bin/tini","--","/usr/local/bin/docker-entrypoint.sh"]

# Default command starts Jenkins
CMD ["bash","-lc","exec /usr/bin/java -jar /usr/share/java/jenkins.war --httpPort=8080"]
