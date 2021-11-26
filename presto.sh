#!/usr/bin/env bash

set -e
# This script helps deploying presto cluster on k8s.

pushd() {
  command pushd "$@" >/dev/null
}
popd() {
  command popd "$@" >/dev/null
}

function print_usage() {
  echo "Usage: presto [COMMAND] [OPTIONS]"
  echo "  where COMMAND is one of:"
  echo "  deploy                   deploy presto cluster"
  echo "  teardown                 teardown existing presto cluster"
  echo ""
  echo "each command print help when invoked w/o parameters."
}

function print_deploy_usage() {
  echo "Usage: presto deploy [OPTIONS]"
  echo "OPTIONS :"
  echo "  --namespace=NAMESPACE            k8s namespace (Default: default)."
  echo "  --image=IMAGE                    presto docker image (Default: r.addops.soft.360.cn/sycp-container/presto-server:0.240-qihoo.1)."
  echo "  --coordinator-cores=NUM          coordinator cpu cores (Default: 4)."
  echo "  --coordinator-memory=MEM         coordinator Memory (e.g. 1000M, 2G) (Default: 16G)."
  echo "  --worker-cores=NUM               Number of cores used by each worker (Default: 4)."
  echo "  --worker-memory=MEM              Memory per worker (e.g. 1000M, 2G) (Default: 32G)."
  echo "  --num-workers=NUM                Number of workers to deploy initially (Default: 100)."
  echo "  --max-workers=NUM                Max number of workers to scale out when CPU is high (Default: 200)."
  echo "  --cli                            Whether enter into presto cli after deploy (Default: false)."

}

function print_teardown_usage() {
  echo "Usage: presto teardown [OPTIONS]"
  echo "OPTIONS :"
  echo "  --namespace=NAMESPACE            k8s namespace of existing presto."

}

function internal_deploy() {
  for i in "$@"; do
    case $i in
    --namespace=*)
      NAMESPACE="${i#*=}"
      shift # past argument=value
      ;;
    --image=*)
      IMAGE="${i#*=}"
      shift # past argument=value
      ;;
    --coordinator-cores=*)
      COORDINATOR_CORES="${i#*=}"
      shift # past argument=value
      ;;
    --coordinator-memory=*)
      COORDINATOR_MEMORY="${i#*=}"
      shift # past argument=value
      ;;
    --worker-cores=*)
      COORDINATOR_MEMORY="${i#*=}"
      shift # past argument=value
      ;;
    --worker-memory=*)
      COORDINATOR_MEMORY="${i#*=}"
      shift # past argument=value
      ;;
    --num-workers=*)
      NUM_WORKERS="${i#*=}"
      shift # past argument=value
      ;;
    --max-workers=*)
      MAX_WORKERS="${i#*=}"
      shift # past argument=value
      ;;
    --cli)
      CLI=true
      shift # past
      ;;
    *)
      print_deploy_usage
      exit
      ;;
    esac
  done

  export NAMESPACE=${NAMESPACE:-"default"}
  export IMAGE=${IMAGE:-"r.addops.soft.360.cn/sycp-container/presto-server:0.240-qihoo.1"}
  export COORDINATOR_CORES=${COORDINATOR_CORES:-"4"}
  export COORDINATOR_MEMORY=${COORDINATOR_MEMORY:-"16G"}
  export WORKER_CORES=${WORKER_CORES:-"4"}
  export WORKER_MEMORY=${WORKER_MEMORY:-"32G"}
  export NUM_WORKERS=${NUM_WORKERS:-"100"}
  export MAX_WORKERS=${MAX_WORKERS:-"200"}
  export CLI=${CLI:-false}

  echo "=== deploying presto on k8s ==="
  pushd presto/
  kubectl -n ${NAMESPACE} create configmap hadoop-conf --dry-run \
    --from-file=hadoop-conf \
    -o yaml | kubectl apply -f -
  kubectl -n ${NAMESPACE} create configmap presto-conf-coordinator --dry-run \
    --from-file=presto-conf/coordinator \
    -o yaml | kubectl apply -f -
  kubectl -n ${NAMESPACE} create configmap presto-conf-worker --dry-run \
    --from-file=presto-conf/worker \
    -o yaml | kubectl apply -f -
  envsubst <presto.yaml | kubectl -n ${NAMESPACE} apply -f -
  popd
  echo "=== presto is ready, please visit cluster ui: ==="
  INGRESS_HOST=$(kubectl -n ${NAMESPACE} get ingress presto-ui -o jsonpath='{.spec.rules[0].host}')
  PRESTO_UI="http://"${INGRESS_HOST}
  echo ${PRESTO_UI}
  if [ "$CLI" = true ]; then
    echo "=== entering into presto cli ==="
    USER=$(id -un)
    while : ; do
      STATUS=$(kubectl -n ${NAMESPACE} get pod presto-cli -o jsonpath='{.status.phase}')
      if [ "$STATUS" = "Running" ]; then
        kubectl -n ${NAMESPACE} exec -it presto-cli -- /opt/presto-server/bin/presto-cli --user ${USER} --server http://presto:8080
        break
      else
        sleep 2
      fi
    done
  fi

}

function internal_teardown() {
  for i in "$@"; do
    case $i in
    --namespace=*)
      NAMESPACE="${i#*=}"
      shift # past argument=value
      ;;
    *)
      print_deploy_usage
      exit
      ;;
    esac
  done

  export NAMESPACE=${NAMESPACE:-"default"}

  echo "=== teardown presto cluster of namespace "${NAMESPACE}" on k8s ==="
  pushd presto/
  kubectl -n ${NAMESPACE} delete configmap hadoop-conf --ignore-not-found=true
  kubectl -n ${NAMESPACE} delete configmap presto-conf-coordinator --ignore-not-found=true
  kubectl -n ${NAMESPACE} delete configmap presto-conf-worker --ignore-not-found=true
  envsubst <presto.yaml | kubectl -n ${NAMESPACE} delete -f -
  popd
  echo "=== presto of namespace "${NAMESPACE}" is offline  ==="

}

function deploy() {
  if [ $# = 0 ]; then
    print_deploy_usage
    exit
  fi
  internal_deploy "$@"
}

function teardown() {
  if [ $# = 0 ]; then
    print_teardown_usage
    exit
  fi
  internal_teardown "$@"
}

if [ $# = 0 ]; then
  print_usage
  exit
fi

COMMAND=$1
case $COMMAND in
deploy)
  shift
  # call deploy function
  deploy "$@"

  ;;
teardown)
  shift
  # call teardown function
  teardown "$@"

  ;;
# usage flags
--help | -help | -h | *)
  print_usage
  exit
  ;;
esac
