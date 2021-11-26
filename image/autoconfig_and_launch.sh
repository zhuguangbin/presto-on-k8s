#!/bin/bash

set -e

cp /opt/presto-server/etc/node.properties.template /opt/presto-server/etc/node.properties
echo "node.id=$HOSTNAME" >> /opt/presto-server/etc/node.properties

/opt/presto-server/bin/launcher run
