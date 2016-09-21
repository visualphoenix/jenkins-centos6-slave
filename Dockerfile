FROM centos:6.7

RUN GOSU_VERSION=1.9 \
 && yum install -y wget openssh-clients tar \
 && gpg --keyserver pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
 && wget -O /bin/gosu --no-check-certificate "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-amd64" \
 && wget -O /tmp/gosu.asc --no-check-certificate "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-amd64.asc" \
 && gpg --verify /tmp/gosu.asc /bin/gosu \
 && rm /tmp/gosu.asc \
 && chmod +x /bin/gosu

ENV SWARM_VERSION 2.0
RUN  wget http://repo.jenkins-ci.org/releases/org/jenkins-ci/plugins/swarm-client/$SWARM_VERSION/swarm-client-$SWARM_VERSION-jar-with-dependencies.jar -O /opt/swarm-client-$SWARM_VERSION-jar-with-dependencies.jar \
  && chmod 644 /opt/swarm-client-$SWARM_VERSION-jar-with-dependencies.jar

ENV JENKINS_HOME /jenkins
WORKDIR $JENKINS_HOME
RUN mkdir -p $JENKINS_HOME \
  && chown -R 12321:12321 $JENKINS_HOME \
  && /usr/sbin/useradd --uid 12321 --gid 100 --groups 100 -m -d $JENKINS_HOME -s /bin/bash -c "Jenkins user running java -jar /opt/swarm-client-$SWARM_VERSION-jar-with-dependencies.jar" jenkins

ENV DOCKER_VERSION 1.6.2
RUN wget "https://get.docker.io/builds/Linux/x86_64/docker-$DOCKER_VERSION" -O /usr/bin/docker
RUN chmod a+x /usr/bin/docker

RUN cd /tmp \
 && wget \
  --no-cookies \
  --no-check-certificate \
  --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" \
  "http://download.oracle.com/otn-pub/java/jdk/8u60-b27/jre-8u60-linux-x64.rpm" \
 && yum localinstall -y jre-8u60-linux-x64.rpm \
 && rm jre-8u60-linux-x64.rpm

ENV MAVEN_VERSION 3.0.5
RUN wget -q -O- "http://mirror.cc.columbia.edu/pub/software/apache/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz" | tar xz -C /usr/local \
 && ln -s apache-maven-${MAVEN_VERSION} maven \
 && echo 'export M2_HOME=/usr/local/maven' > /etc/profile.d/maven.sh \
 && echo 'export PATH=${M2_HOME}/bin:${PATH}' >> /etc/profile.d/maven.sh \
 && true

ADD sudo-wrapper.sh /usr/bin/sudo
RUN chmod +x /usr/bin/sudo

ADD start.sh /usr/local/sbin/start.sh
RUN chmod 755 /usr/local/sbin/start.sh

VOLUME ["/jenkins/.m2/repository"\
,"/jenkins/workspace"\
,"/jenkins/.jenkins/cache"]

CMD ["/usr/local/sbin/start.sh"]
