# presto-on-k8s

deploy presto cluster on k8s

### Requirement
  1. One existing k8s cluster
  2. kubectl command-line tool that can access the above k8s cluster. If absent, refer to [installation doc][https://kubernetes.io/docs/tasks/tools/install-kubectl/]
  3. Docker Engine if you want to build presto docker image. If absent, refer to [installation doc][https://docs.docker.com/engine/install/]
  4. envsubst for template environment substitution.

### Building Docker Image

`./build_image.sh`

You could export the following Env:
* `export REPONAME=zhuguangbin` # docker image repo you want to push, _r.addops.soft.360.cn/sycp-container_ by default
* `export PRESTOVER=0.240` # prestodb version, _0.240-qihoo.1_ by default

### Deploying Presto on K8S

```
./presto.sh 
Usage: presto [COMMAND] [OPTIONS]
  where COMMAND is one of:
  deploy                   deploy presto cluster
  teardown                 teardown existing presto cluster

each command print help when invoked w/o parameters.

```

```
./presto.sh deploy
Usage: presto deploy [OPTIONS]
OPTIONS :
  --namespace=NAMESPACE            k8s namespace (Default: default).
  --image=IMAGE                    presto docker image (Default: r.addops.soft.360.cn/sycp-container/presto-server:0.240-qihoo.1).
  --coordinator-cores=NUM          coordinator cpu cores (Default: 4).
  --coordinator-memory=MEM         coordinator Memory (e.g. 1000M, 2G) (Default: 16G).
  --worker-cores=NUM               Number of cores used by each worker (Default: 12).
  --worker-memory=MEM              Memory per worker (e.g. 1000M, 2G) (Default: 64G).
  --num-workers=NUM                Number of workers to deploy (Default: 4).
  --max-workers=NUM                Max number of workers to scale out when CPU is high (Default: 100).
  --cli                            Whether enter into presto cli after deploy (Default: false).

```

```
./presto.sh deploy --namespace=default --num-workers=4 --cli
=== deploying presto on k8s ===
configmap/presto-cfg configured
service/presto unchanged
deployment.apps/presto-coordinator configured
statefulset.apps/presto-worker configured
ingress.extensions/presto-ui unchanged
pod/presto-cli unchanged
=== presto is ready, please visit cluster ui: ===
http://presto.default.shbt.k8s.ultron.ads.qihoo.net
=== entering into presto cli ===
presto> show catalogs;
 Catalog 
---------
 hive    
 memory  
 system  
 tpcds   
(4 rows)

Query 20210131_112041_00005_27qeh, FINISHED, 4 nodes
Splits: 70 total, 70 done (100.00%)
0:00 [0 rows, 0B] [0 rows/s, 0B/s]

```

### Teardown Presto cluster

```
./presto.sh teardown                                        
Usage: presto teardown [OPTIONS]
OPTIONS :
  --namespace=NAMESPACE            k8s namespace of existing presto.

```

```
./presto.sh teardown --namespace=default
=== teardown presto cluster of namespace default on k8s ===
configmap "presto-cfg" deleted
service "presto" deleted
deployment.apps "presto-coordinator" deleted
statefulset.apps "presto-worker" deleted
ingress.extensions "presto-ui" deleted
pod "presto-cli" deleted
=== presto of namespace default is offline  ===

```
