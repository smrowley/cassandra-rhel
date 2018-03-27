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
wget -q -O /usr/local/bin/dumb-init https://github.com/Yelp/dumb-init/releases/download/v${DUMB_INIT_VERSION}/dumb-init_${DUMB_INIT_VERSION}_amd64
chmod +x /usr/local/bin/dumb-init

#verify dumb-init checksum
wget -q -O /tmp/dumb-init-sha256sums https://github.com/Yelp/dumb-init/releases/download/v${DUMB_INIT_VERSION}/sha256sums

DUMB_INIT_CHECKSUM=$(sha256sum /usr/local/bin/dumb-init | cut -c 1-64)
DUMB_INIT_HASH=$(grep "dumb-init_${DUMB_INIT_VERSION}_amd64$" /tmp/dumb-init-sha256sums | cut -c 1-64)

if [[ $DUMB_INIT_CHECKSUM == $DUMB_INIT_HASH ]]; then
  echo "Valid checksum for dumb-init binary"
else
  echo "Invalid checksum for dumb-init binary"
  echo "binary: $DUMB_INIT_HASH"
  echo "checksum: $DUMB_INIT_CHECKSUM"
  exit 1
fi

rm -f /tmp/dumb-init-sha256sums
unset DUMB_INIT_CHECKSUM DUMB_INIT_HASH

#download cassandra
CASSANDRA_PATH="cassandra/${CASSANDRA_VERSION}/apache-cassandra-${CASSANDRA_VERSION}-bin.tar.gz"
CASSANDRA_DOWNLOAD="http://www.apache.org/dyn/closer.cgi?path=/${CASSANDRA_PATH}&as_json=1"
CASSANDRA_MIRROR=`wget -q -O - ${CASSANDRA_DOWNLOAD} | grep -oP "(?<=\"preferred\": \")[^\"]+"`

echo "Downloading Apache Cassandra from $CASSANDRA_MIRROR$CASSANDRA_PATH..."
wget -q -O /tmp/apache-cassandra-bin.tar.gz $CASSANDRA_MIRROR$CASSANDRA_PATH

#verify apache cassandra checksum
wget -O /tmp/apache-cassandra-md5sum https://www-us.apache.org/dist/cassandra/$CASSANDRA_VERSION/apache-cassandra-$CASSANDRA_VERSION-bin.tar.gz.md5

CASSANDRA_CHECKSUM=$(cat /tmp/apache-cassandra-md5sum)
CASSANDRA_HASH=$(md5sum /tmp/apache-cassandra-bin.tar.gz | cut -c 1-32)

if [[ $CASSANDRA_CHECKSUM == $CASSANDRA_HASH ]]; then
  echo "Valid checksum for apache cassandra download"
else
  echo "Invalid checksum for apache cassandra download"
  echo "download hash: $CASSANDRA_HASH"
  echo "checksum: $CASSANDRA_CHECKSUM"
  exit 1
fi

#unpack tar file
tar -xzf /tmp/apache-cassandra-bin.tar.gz -C /usr/local

#cleanup
rm -f /tmp/apache-cassandra-md5sum /tmp/apache-cassandra-bin.tar.gz
unset CASSANDRA_CHECKSUM CASSANDRA_HASH

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
