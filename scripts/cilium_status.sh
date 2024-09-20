!#/usr/bin/env bash

CLUSTER1=cilium-demo-cluster1
CLUSTER2=cilium-demo-cluster2
CLUSTER3=cilium-demo-cluster3

for ctx in $CLUSTER1 $CLUSTER2 $CLUSTER3; do
  echo "Context: $ctx"
  cilium clustermesh status --context $ctx
done