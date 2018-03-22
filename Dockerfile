# Copyright 2017 The Kubernetes Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#FROM registry.access.redhat.com/rhel:7.4
FROM registry.access.redhat.com/redhat-openjdk-18/openjdk18-openshift:latest


#ARG BUILD_DATE
#ARG VCS_REF
#ARG CASSANDRA_VERSION
#ARG DEV_CONTAINER

#LABEL \
#    org.label-schema.build-date=$BUILD_DATE \
#    org.label-schema.docker.dockerfile="/Dockerfile" \
#    org.label-schema.license="Apache License 2.0" \
#    org.label-schema.name="k8s-for-greeks/docker-cassandra-k8s" \
#    org.label-schema.url="https://github.com/k8s-for-greeks/" \
#    org.label-schema.vcs-ref=$VCS_REF \
#    org.label-schema.vcs-type="Git" \
#    org.label-schema.vcs-url="https://github.com/k8s-for-greeks/docker-cassandra-k8s"

RUN java -version

ENV CASSANDRA_VERSION=3.11.2 \
#ENV CASSANDRA_VERSION=3.0.15 \
    DEV_CONTAINER=true

ENV CASSANDRA_HOME=/usr/local/apache-cassandra-${CASSANDRA_VERSION} \
    CASSANDRA_CONF=/etc/cassandra \
    CASSANDRA_DATA=/cassandra_data \
    CASSANDRA_LOGS=/var/log/cassandra \
    PATH=${PATH}:/usr/local/apache-cassandra-${CASSANDRA_VERSION}/bin
    #JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64 \
    #PATH=${PATH}:/usr/lib/jvm/java-8-openjdk-amd64/bin:/usr/local/apache-cassandra-${CASSANDRA_VERSION}/bin

USER root

ADD files /

RUN chmod u+x /build.sh && \
    /build.sh
#RUN clean-install bash \
#    && /build.sh \
#    && rm /build.sh

# JVM_OPTS="$JVM_OPTS -Dcom.sun.management.jmxremote.authenticate=true" to false
# We need to be able to connect to the cluster from cassandra-reaper
RUN sed -ri 's/authenticate=true/authenticate=false/' /etc/cassandra/cassandra-env.sh

#RUN java -version

#override the s2i entrypoint
ENTRYPOINT ["/usr/bin/env"]

VOLUME ["/$CASSANDRA_DATA"]

# 7000: intra-node communication
# 7001: TLS intra-node communication
# 7199: JMX
# 9042: CQL
# 9160: thrift service
EXPOSE 7000 7001 7199 9042 9160

CMD ["/usr/local/bin/dumb-init", "/bin/bash", "/run.sh"]
