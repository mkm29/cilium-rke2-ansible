#!/usr/bin/env bash

source ./common.sh

for ctx in $CLUSTER1 $CLUSTER2 $CLUSTER3; do
  echo "Context: $ctx"
  cilium clustermesh status --context $ctx
done