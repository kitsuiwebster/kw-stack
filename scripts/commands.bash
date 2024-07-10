#!/bin/bash

COMMAND=$1

case $COMMAND in
  create)
    echo "Starting Minikube..."
    minikube start
    echo "Setting kubectl context to minikube..."
    kubectl config use-context minikube
    echo "Applying Kubernetes manifests..."
    kubectl apply -f manifests/couchdb/couchdb-deployment.yaml
    kubectl apply -f manifests/keycloak/keycloak-deployment.yaml
    kubectl apply -f manifests/gravitee/gravitee-deployment.yaml
    kubectl apply -f manifests/ingress/ingress.yaml  # Optional
    echo "Cluster created and applications deployed."
    ;;
  delete)
    echo "Stopping and deleting Minikube cluster..."
    minikube stop
    minikube delete
    echo "Cluster deleted."
    ;;
  pause)
    echo "Pausing Minikube cluster..."
    minikube pause
    echo "Cluster paused."
    ;;
  resume)
    echo "Resuming Minikube cluster..."
    minikube unpause
    echo "Cluster resumed."
    ;;
  *)
    echo "Usage: $0 {create|delete|pause|resume}"
    exit 1
    ;;
esac
