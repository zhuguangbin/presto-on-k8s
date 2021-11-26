#!/bin/bash

set -e

REPONAME=${REPONAME:-'r.addops.soft.360.cn/sycp-container'}
PRESTOVER=${PRESTOVER:-'0.240-qihoo.1'}

## Build Presto-server

docker build --build-arg PRESTO_VER=$PRESTOVER -t presto-server:$PRESTOVER image/

# Tag and push to the public docker repository.
docker tag presto-server:$PRESTOVER $REPONAME/presto-server:$PRESTOVER
docker push $REPONAME/presto-server:$PRESTOVER
