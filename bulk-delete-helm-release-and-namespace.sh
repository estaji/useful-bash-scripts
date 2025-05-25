#!/bin/bash

while IFS= read -r NAMESPACE; do
  
  HELM_RELEASE="${NAMESPACE::-4}"

  echo "start deleting namespace: $NAMESPACE package: $HELM_RELEASE ..."

  helm uninstall -n $NAMESPACE $HELM_RELEASE

  sleep 1

  kubectl delete ns $NAMESPACE
  
  echo "end deleting namespace: $NAMESPACE package: $HELM_RELEASE ..."

  sleep 1

done < <(kubectl get ns -A | grep -e "-dev" | awk '{print $1}')
