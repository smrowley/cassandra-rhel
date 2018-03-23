#!/bin/bash

# Copyright 2018 The Kubernetes Authors.
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


set -o errexit
set -o nounset
set -o pipefail

yum -y update && yum -y upgrade

yum -y install wget

#download dumb-init
DUMB_INIT_VERSION="1.2.1"
wget -O /usr/local/bin/dumb-init https://github.com/Yelp/dumb-init/releases/download/v${DUMB_INIT_VERSION}/dumb-init_${DUMB_INIT_VERSION}_amd64
chmod +x /usr/local/bin/dumb-init

#verify dumb-init checksum
wget -O /tmp/dumb-init-sha256sums https://github.com/Yelp/dumb-init/releases/download/v${DUMB_INIT_VERSION}/sha256sums

if [ sha256sum /usr/local/bin/dumb-init != grep "dumb-init_1.2.1_amd64$" /tmp/dumb-init-sha256sums | cut -d ' ' -f 1 ]; then
  echo "Invalid checksum for dumb-init binary"
  exit 1
else
  echo "Valid checksum for dumb-init binary"
fi

rm -f /tmp/dumb-init-sha256sums

CASSANDRA_PATH="cassandra/${CASSANDRA_VERSION}/apache-cassandra-${CASSANDRA_VERSION}-bin.tar.gz"
CASSANDRA_DOWNLOAD="http://www.apache.org/dyn/closer.cgi?path=/${CASSANDRA_PATH}&as_json=1"
CASSANDRA_MIRROR=`wget -q -O - ${CASSANDRA_DOWNLOAD} | grep -oP "(?<=\"preferred\": \")[^\"]+"`

echo "Downloading Apache Cassandra from $CASSANDRA_MIRROR$CASSANDRA_PATH..."
wget -q -O - $CASSANDRA_MIRROR$CASSANDRA_PATH \
    | tar -xzf - -C /usr/local

mkdir -p /cassandra_data/data
mkdir -p /etc/cassandra

mv /logback.xml /cassandra.yaml /jvm.options /etc/cassandra/
mv /usr/local/apache-cassandra-${CASSANDRA_VERSION}/conf/cassandra-env.sh /etc/cassandra/

adduser --no-create-home cassandra
chmod +x /ready-probe.sh
chown cassandra: /ready-probe.sh

DEV_IMAGE=${DEV_CONTAINER:-}
if [ ! -z "$DEV_IMAGE" ]; then
    yum -y install python;
else
    rm -rf  $CASSANDRA_HOME/pylib;
fi
