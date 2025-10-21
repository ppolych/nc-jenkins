 => ERROR [4/7] RUN set -eux;     mkdir -p /opt/jenkins "/var/jenkins_home";     LTS_VER="$(curl -fsSL https://updates.  3.4s
------
 > [4/7] RUN set -eux;     mkdir -p /opt/jenkins "/var/jenkins_home";     LTS_VER="$(curl -fsSL https://updates.jenkins.io/stable/latestCore.txt)";     curl -fsSL "https://get.jenkins.io/war-stable/${LTS_VER}/jenkins.war" -o /opt/jenkins/jenkins.war;     curl -fsSL "https://get.jenkins.io/war-stable/${LTS_VER}/jenkins.war.sha256" -o /tmp/jenkins.war.sha256;     echo "$(cat /tmp/jenkins.war.sha256)  /opt/jenkins/jenkins.war" | sha256sum -c -;     rm -f /tmp/jenkins.war.sha256:
0.168 + mkdir -p /opt/jenkins /var/jenkins_home
0.172 + curl -fsSL https://updates.jenkins.io/stable/latestCore.txt
0.905 + LTS_VER=2.528.1
0.905 + curl -fsSL https://get.jenkins.io/war-stable/2.528.1/jenkins.war -o /opt/jenkins/jenkins.war
2.667 + curl -fsSL https://get.jenkins.io/war-stable/2.528.1/jenkins.war.sha256 -o /tmp/jenkins.war.sha256
3.309 + sha256sum -c -
3.310 + cat /tmp/jenkins.war.sha256
3.312 + echo d630dca265f75a8d581f127a9234f1679d4b0800a8f370d03ad4a154ceb7295b jenkins.war  /opt/jenkins/jenkins.war
3.313 sha256sum: 'jenkins.war  /opt/jenkins/jenkins.war': No such file or directory
3.313 jenkins.war  /opt/jenkins/jenkins.war: FAILED open or read
3.313 sha256sum: WARNING: 1 listed file could not be read
------
Dockerfile:34

--------------------

  33 |     ENV JENKINS_HOME=/var/jenkins_home

  34 | >>> RUN set -eux; \

  35 | >>>     mkdir -p /opt/jenkins "$JENKINS_HOME"; \

  36 | >>>     LTS_VER="$(curl -fsSL https://updates.jenkins.io/stable/latestCore.txt)"; \

  37 | >>>     curl -fsSL "https://get.jenkins.io/war-stable/${LTS_VER}/jenkins.war" -o /opt/jenkins/jenkins.war; \

  38 | >>>     curl -fsSL "https://get.jenkins.io/war-stable/${LTS_VER}/jenkins.war.sha256" -o /tmp/jenkins.war.sha256; \

  39 | >>>     echo "$(cat /tmp/jenkins.war.sha256)  /opt/jenkins/jenkins.war" | sha256sum -c -; \

  40 | >>>     rm -f /tmp/jenkins.war.sha256

  41 |

--------------------

failed to solve: process "/bin/sh -c set -eux;     mkdir -p /opt/jenkins \"$JENKINS_HOME\";     LTS_VER=\"$(curl -fsSL https://updates.jenkins.io/stable/latestCore.txt)\";     curl -fsSL \"https://get.jenkins.io/war-stable/${LTS_VER}/jenkins.war\" -o /opt/jenkins/jenkins.war;     curl -fsSL \"https://get.jenkins.io/war-stable/${LTS_VER}/jenkins.war.sha256\" -o /tmp/jenkins.war.sha256;     echo \"$(cat /tmp/jenkins.war.sha256)  /opt/jenkins/jenkins.war\" | sha256sum -c -;     rm -f /tmp/jenkins.war.sha256" did not complete successfully: exit code: 1
