#!/bin/bash -x
source /etc/environment
set -e

mkdir -p /jenkins/.ssh
mkdir -p /jenkins/.m2
find /jenkins -not \( -user 12321 -or -group 12321 \) -exec chown 12321:12321 '{}' \;

set -x
unset HOME
unset USER

unset TOOL_OPTIONS
TOOL_OPTIONS=
if [ ! -z "${JAVA_HOME}" -a -e "${JAVA_HOME}" ] ; then
  JAVA_VERSION=$(java -version 2>&1 | grep version | cut -d'"' -f2 | cut -d'.' -f2)
  TOOL_OPTIONS="${TOOL_OPTIONS:-} -t Java${JAVA_VERSION}=${JAVA_HOME}"
fi

MVN_HOME=/usr/local/maven
if [ ! -z "${MVN_HOME}" -a -e "${MVN_HOME}" ] ; then
  TOOL_OPTIONS="${TOOL_OPTIONS:-} -t Maven=${MVN_HOME}"
fi

trap "curl -X POST http://jenkins/computer/$JENKINS_SWARM_NAME/doDelete/api/json" SIGHUP SIGINT SIGTERM
/bin/gosu jenkins java -jar /opt/swarm-client-$SWARM_VERSION-jar-with-dependencies.jar \
      -fsroot ${JENKINS_HOME:-/jenkins} \
      -master "${JENKINS_MASTER_URL:-http://$MASTER_PORT_8080_TCP_ADDR:$MASTER_PORT_8080_TCP_PORT}" \
      -mode "${JENKINS_SWARM_MODE:-exclusive}" \
      -executors "${JENKINS_SWARM_EXECUTORS:-1}" \
      -username "$JENKINS_SLAVE_USER" \
      -password "$JENKINS_SLAVE_PASSWORD" \
      -name "$JENKINS_SWARM_NAME" \
      -labels "$JENKINS_SWARM_LABELS" \
      -description "$JENKINS_SWARM_DESCRIPTION"
