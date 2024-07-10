#!/bin/bash

echo "Starting Minikube..."
minikube start

echo "Setting kubectl context to minikube..."
kubectl config use-context minikube

echo "Applying Kubernetes manifests..."
kubectl apply -f manifests/couchdb/couchdb-deployment.yaml
kubectl apply -f manifests/keycloak/keycloak-deployment.yaml
kubectl apply -f manifests/gravitee/gravitee-deployment.yaml
kubectl apply -f manifests/ingress/ingress.yaml 

echo "Cluster created and applications deployed."
