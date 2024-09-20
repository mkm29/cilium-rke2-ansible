#!/usr/bin/env bash

# source common.sh
source ./common.sh

# for each context get pod usage sorted by memory
for context in $CLUSTER1 $CLUSTER2 $CLUSTER3 $CLUSTER4; do
    echo "Pod usage in context $context"
    kubectl --context $context top pods --all-namespaces --sort-by=memory
done