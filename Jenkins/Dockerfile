FROM openjdk:8-jdk

ARG VERSION=3.9
ARG JENKINS_SLAVE_BRANCH=master

LABEL maintainer "chgeuer@microsoft.com"

ENV HOME /home/jenkins

RUN groupadd -g 10000 jenkins && \
    useradd -c "Jenkins user" -d $HOME -u 10000 -g 10000 -m jenkins && \
    curl --create-dirs -sSLo /usr/share/jenkins/slave.jar https://repo.jenkins-ci.org/public/org/jenkins-ci/main/remoting/${VERSION}/remoting-${VERSION}.jar && \
    chmod 0755 /usr/share/jenkins && \
    chmod 0644 /usr/share/jenkins/slave.jar && \
    curl --create-dirs -sSLo /usr/local/bin/jenkins-slave https://raw.githubusercontent.com/jenkinsci/docker-jnlp-slave/${JENKINS_SLAVE_BRANCH}/jenkins-slave && \
    chmod 0755 /usr/local/bin/jenkins-slave

USER jenkins
WORKDIR /home/jenkins
RUN mkdir /home/jenkins/.jenkins
VOLUME ["/home/jenkins/.jenkins"]

ENTRYPOINT ["/usr/local/bin/jenkins-slave"]
