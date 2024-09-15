#!/usr/bin/env bash

usage() {
  echo "Usage: $0 [--sync-ca] [--contexts <context1,context2,...>] [--enable-mesh] [--mesh-service-type <service-type>]"
  exit 1
}

extract_args() {
  while [ $# -gt 0 ]; do
    case $1 in
      --sync-ca)
        SYNC_CA=true
        ;;
      --contexts)
        shift
        CONTEXTS=$1
        ;;
      --enable-mesh)
        ENABLE_MESH=true
        ;;
      --mesh-service-type)
        shift
        MESH_SERVICE_TYPE=$1
        ;;
      *)
        usage
        ;;
    esac
    shift
  done
}

main() {
  declare -A CLUSTERS
  # if --help print usage
  if [ "$1" = "--help" ]; then
    usage
  fi
  extract_args "$@"

  # Set IFS to comma (,) to split the string
  IFS=',' read -r -a context_array <<< "$CONTEXTS"

  # print the context_array
  echo "Contexts: ${context_array[@]}"

  if [ "$SYNC_CA" = true ]; then
    # get first context
    c1=${context_array[0]}
    # get length of context_array
    len=${#context_array[@]}
    # for every cluster except the first one
    for (( i=1; i<$len; i++ )); do
      c2=${context_array[$i]}
      kubectl delete secret -n kube-system cilium-ca --context=$c2
      kubectl get secret -n kube-system cilium-ca -o yaml --context=$c1 | \
        kubectl create -f - --context=$c2
    done
  fi

  if [ "$enable_mesh" = true ]; then
    # enable clustermesh on each cluster
    for context in "${context_array[@]}"; do
      cilium clustermesh enable --context $context --service-type $MESH_SERVICE_TYPE
    done
  fi

  for context in "${context_array[@]}"; do
    # need to connect cluster1 with every other cluster
    c1=${context_array[0]}
    for (( i=1; i<$len; i++ )); do
      cilium clustermesh connect --context $c1 --destination-context ${context_array[$i]}
  done
}

main "$@"