FROM openjdk:8-jdk

ARG VERSION=3.9

ENV HOME /home/jenkins

RUN groupadd -g 10000 jenkins && \
    useradd -c "Jenkins user" -d $HOME -u 10000 -g 10000 -m jenkins && \
    curl --create-dirs -sSLo /usr/share/jenkins/slave.jar https://repo.jenkins-ci.org/public/org/jenkins-ci/main/remoting/${VERSION}/remoting-${VERSION}.jar && \
    curl --create-dirs -sSLo /usr/local/bin/jenkins-slave https://raw.githubusercontent.com/jenkinsci/docker-jnlp-slave/master/jenkins-slave && \
    chmod 755 /usr/share/jenkins && \
    chmod 644 /usr/share/jenkins/slave.jar

USER jenkins
RUN mkdir /home/jenkins/.jenkins
VOLUME /home/jenkins/.jenkins
WORKDIR /home/jenkins

ENTRYPOINT ["/usr/local/bin/jenkins-slave"]
