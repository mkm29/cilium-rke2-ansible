#!/usr/bin/env bash

# cluster_mesh.sh --create-ca --context1 <context1> --context2 <context2> --enable-mesh

usage() {
  echo "Usage: $0 [--create-ca] [--context1 <context1>] [--context2 <context2>] [--enable-mesh]"
  exit 1
}

extract_args() {
  while [ $# -gt 0 ]; do
    case $1 in
      --create-ca)
        is_configured_ca=false
        ;;
      --context1)
        shift
        CLUSTER1=$1
        ;;
      --context2)
        shift
        CLUSTER2=$1
        ;;
      --enable-mesh)
        enable_mesh=true
        ;;
      *)
        usage
        ;;
    esac
    shift
  done
}

main() {
  # if --help print usage
  if [ "$1" = "--help" ]; then
    usage
  fi
  extract_args "$@"
  if [ "$is_configured_ca" = false ]; then
    kubectl --context=$CLUSTER2 delete secret -n kube-system cilium-ca
    kubectl --context=$CLUSTER1 get secret -n kube-system cilium-ca -o yaml | \
      kubectl --context $CLUSTER2 create -f -
  fi

  if [ "$enable_mesh" = true ]; then
    cilium clustermesh enable --context $CLUSTER1 --service-type ClusterIP
    cilium clustermesh enable --context $CLUSTER2 --service-type ClusterIP
  fi

  cilium clustermesh connect --context $CLUSTER1 --destination-context $CLUSTER2
  cilium clustermesh connect --context $CLUSTER2 --destination-context $CLUSTER1
}

main "$@"