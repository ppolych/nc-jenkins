FROM debian:13.1-slim

# --- Base tools + Java 21 runtime (Jenkins needs only JRE) ---
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
      ca-certificates curl gnupg git \
      openjdk-21-jre-headless \
      gosu tini \
    ; \
    rm -rf /var/lib/apt/lists/*

# --- Official Docker CLI + Compose v2 (static) ---
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

# --- Jenkins LTS ---
RUN set -eux; \
    curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | gpg --dearmor -o /usr/share/keyrings/jenkins.gpg; \
    echo "deb [signed-by=/usr/share/keyrings/jenkins.gpg] https://pkg.jenkins.io/debian-stable binary/" > /etc/apt/sources.list.d/jenkins.list; \
    apt-get update; \
    apt-get install -y --no-install-recommends jenkins; \
    rm -rf /var/lib/apt/lists/*

# --- Users & perms ---
RUN set -eux; \
    if ! getent group docker >/dev/null; then groupadd -r docker; fi; \
    usermod -aG docker jenkins
ENV JENKINS_HOME=/var/jenkins_home
RUN mkdir -p "$JENKINS_HOME" && chown -R jenkins:jenkins "$JENKINS_HOME"

# --- Entrypoint ---
ADD docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# --- Ports ---
EXPOSE 8080
EXPOSE 50000
EXPOSE 8200-8220

ENTRYPOINT ["/usr/bin/tini","--","/usr/local/bin/docker-entrypoint.sh"]
CMD ["bash","-lc","exec /usr/bin/java -jar /usr/share/java/jenkins.war --httpPort=8080"]
