#!/bin/bash

COMMAND=$1

update_hosts() {
  # Get the new Minikube IP
  MINIKUBE_IP=$(minikube ip)

  # Define the hostnames
  HOSTNAMES=("couchdb.local" "gravitee.local" "keycloak.local" "nestjs.local" "reactjs.local")

  # Backup the original /etc/hosts file
  sudo cp /etc/hosts /etc/hosts.bak

  # Remove old Minikube entries
  for HOST in "${HOSTNAMES[@]}"; do
    sudo sed -i "/$HOST/d" /etc/hosts
  done

  # Add new Minikube entries
  for HOST in "${HOSTNAMES[@]}"; do
    echo "$MINIKUBE_IP $HOST" | sudo tee -a /etc/hosts
  done

  echo "👉 Updated /etc/hosts with new Minikube IP: $MINIKUBE_IP"
}

wait_for_ingress() {
  echo "👉 Waiting for NGINX Ingress controller to be ready..."
  while ! kubectl get pods -n ingress-nginx | grep -q '1/1'; do
    echo "👉 NGINX Ingress controller is not ready yet. Waiting..."
    sleep 1
  done
  echo "👉 NGINX Ingress controller is ready."
}

case $COMMAND in
  create)
    echo "👉 Starting Minikube..."
    minikube start
    echo "👉 Enabling NGINX Ingress controller..."
    minikube addons enable ingress
    echo "👉 Setting kubectl context to minikube..."
    kubectl config use-context minikube
    wait_for_ingress
    echo "👉 Applying Kubernetes manifests..."
    kubectl apply -f manifests/couchdb/couchdb-deployment.yaml
    kubectl apply -f manifests/couchdb/couchdb-ingress.yaml
    kubectl apply -f manifests/keycloak/keycloak-deployment.yaml
    kubectl apply -f manifests/keycloak/keycloak-ingress.yaml
    kubectl apply -f manifests/gravitee/gravitee-deployment.yaml
    kubectl apply -f manifests/gravitee/gravitee-ingress.yaml
    kubectl apply -f manifests/nestjs/nestjs-deployment.yaml
    kubectl apply -f manifests/nestjs/nestjs-ingress.yaml
    kubectl apply -f manifests/reactjs/reactjs-deployment.yaml
    kubectl apply -f manifests/reactjs/reactjs-ingress.yaml
    update_hosts
    echo "👉 Cluster created and applications deployed."
    ;;
  delete)
    echo "👉 Stopping and deleting Minikube cluster..."
    minikube stop
    minikube delete
    echo "👉 Cluster deleted."
    ;;
  stop)
    echo "👉 Stopping Minikube cluster..."
    minikube stop
    echo "👉 Cluster stopped."
    ;;
  start)
    echo "👉 Starting Minikube cluster..."
    minikube start
    update_hosts
    echo "👉 Cluster started."
    ;;
  *)
    echo "👉 Usage: $0 {create|delete|stop|start}"
    exit 1
    ;;
esac
