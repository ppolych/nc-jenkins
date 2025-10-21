FROM debian:13.1-slim

# --- Base tools + Java 21 runtime ---
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
      ca-certificates curl gnupg git \
      openjdk-21-jre-headless \
      gosu tini \
    ; \
    rm -rf /var/lib/apt/lists/*

# --- Official Docker CLI + Compose v2 (static binaries) ---
ARG DOCKER_CLI_VERSION=27.3.1
ARG COMPOSE_VERSION=2.29.7
RUN set -eux; \
    arch="$(dpkg --print-architecture)"; \
    case "$arch" in \
      amd64)  DOCKER_URL="https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKER_CLI_VERSION}.tgz"; COMPOSE_URL="https://github.com/docker/compose/releases/download/v${COMPOSE_VERSION}/docker-compose-linux-x86_64";; \
      arm64)  DOCKER_URL="https://download.docker.com/linux/static/stable/aarch64/docker-${DOCKER_CLI_VERSION}.tgz"; COMPOSE_URL="https://github.com/docker/compose/releases/download/v${COMPOSE_VERSION}/docker-compose-linux-aarch64";; \
      *) echo "Unsupported arch: $arch" && exit 1;; \
    esac; \
    mkdir -p /usr/local/bin /usr/local/lib/docker/cli-plugins; \
    curl -fsSL "$DOCKER_URL" -o /tmp/docker.tgz; \
    tar -xzf /tmp/docker.tgz -C /tmp; \
    mv /tmp/docker/docker /usr/local/bin/docker; \
    chmod +x /usr/local/bin/docker; \
    curl -fsSL "$COMPOSE_URL" -o /usr/local/lib/docker/cli-plugins/docker-compose; \
    chmod +x /usr/local/lib/docker/cli-plugins/docker-compose; \
    rm -rf /tmp/docker /tmp/docker.tgz

# --- Jenkins LTS WAR (auto-resolve τρέχουσα LTS + checksum verify) ---
ENV JENKINS_HOME=/var/jenkins_home
RUN set -eux; \
    mkdir -p /opt/jenkins "$JENKINS_HOME"; \
    LTS_VER="$(curl -fsSL https://updates.jenkins.io/stable/latestCore.txt)"; \
    curl -fsSL "https://get.jenkins.io/war-stable/${LTS_VER}/jenkins.war" -o /opt/jenkins/jenkins.war; \
    curl -fsSL "https://get.jenkins.io/war-stable/${LTS_VER}/jenkins.war.sha256" -o /opt/jenkins/jenkins.war.sha256; \
    (cd /opt/jenkins && sha256sum -c jenkins.war.sha256); \
    rm -f /opt/jenkins/jenkins.war.sha256

# --- Create 'jenkins' user and docker group; set permissions ---
RUN set -eux; \
    groupadd -r jenkins; useradd -r -g jenkins -d "$JENKINS_HOME" -s /bin/bash jenkins; \
    if ! getent group docker >/dev/null; then groupadd -r docker; fi; \
    usermod -aG docker jenkins; \
    chown -R jenkins:jenkins "$JENKINS_HOME" /opt/jenkins

# --- Entrypoint (align docker.sock GID, then drop to jenkins) ---
ADD docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# --- Ports ---
EXPOSE 8080
EXPOSE 50000
EXPOSE 8200-8220

ENTRYPOINT ["/usr/bin/tini","--","/usr/local/bin/docker-entrypoint.sh"]
CMD ["bash","-lc","exec /usr/bin/java -jar /opt/jenkins/jenkins.war --httpPort=8080"]
