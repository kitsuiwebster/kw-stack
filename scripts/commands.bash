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
    kubectl apply -f manifests/nestjs/nestjs-deployment.yaml
    kubectl apply -f manifests/reactjs/reactjs-deployment.yaml
    kubectl apply -f manifests/ingress/ingress.yaml
    echo "Cluster created and applications deployed."
    ;;
  delete)
    echo "Stopping and deleting Minikube cluster..."
    minikube stop
    minikube delete
    echo "Cluster deleted."
    ;;
  stop)
    echo "Stopping Minikube cluster..."
    minikube stop
    echo "Cluster stopped."
    ;;
  start)
    echo "Starting Minikube cluster..."
    minikube start
    echo "Cluster started."
    ;;
  *)
    echo "Usage: $0 {create|delete|pause|resume}"
    exit 1
    ;;
esac
