#!/bin/bash

COMMAND=$1

update_hosts() {
  # Get the new Minikube IP
  MINIKUBE_IP=$(minikube ip -p kw-stack -v 5)

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

print_urls_and_credentials() {
  MINIKUBE_IP=$(minikube ip -p kw-stack -v 5)
  echo "👉 Access your services at the following URLs:"
  echo ""
  echo ""
  echo "🛋   CouchDB: http://couchdb.local/_utils"
  echo ""
  echo "🆔  admin"
  echo "🗝️   admin"
  echo ""
  echo ""
  echo "🪐  Gravitee: http://gravitee.local"
  echo ""
  echo "🆔  admin"
  echo "🗝️   admin"
  echo ""
  echo ""
  echo "🔐  Keycloak: http://keycloak.local"
  echo ""
  echo "🆔  admin"
  echo "🗝️   admin"
  echo ""
  echo ""
  echo "⚙️   NestJS: http://nestjs.local"
  echo ""
  echo ""
  echo "⚛️   ReactJS: http://reactjs.local"
  echo ""
  echo ""
}

case $COMMAND in
  create)
    echo "👉 Starting Minikube..."
    minikube start -p kw-stack -v 5
    echo "👉 Enabling NGINX Ingress controller..."
    minikube addons enable ingress -p kw-stack -v 5
    echo "👉 Setting kubectl context to minikube..."
    kubectl config use-context kw-stack
    wait_for_ingress

    # echo "⚛️   Building React app..."
    # (cd reactjs-app && npm install && npm run build)

    # echo "⚛️   Building React Docker image..."
    # eval $(minikube docker-env -p kw-stack)
    # docker build -t reactjs-app:latest ./reactjs-app

    # echo "⚙️   Building NestJS app..."
    # (cd nestjs-app && npm install && npm run build)

    # echo "⚙️   Building NestJS Docker image..."
    # eval $(minikube docker-env -p kw-stack)
    # docker build -t nestjs-app:latest ./nestjs-app

    # echo "🐋 Pulling Gravitee Docker images..."
    # echo "🪐 Gravitee API Management Docker image"
    # docker pull graviteeio/apim-management-api:latest
    # echo "🪐 Gravitee Management Web UI Docker image"
    # docker pull graviteeio/apim-management-ui:latest
    # echo "🪐 Gravitee Gateway Docker image"
    # docker pull graviteeio/apim-gateway:latest
    # echo "🪐 Gravitee Portal Docker image"
    # docker pull graviteeio/apim-portal-ui:latest

    # echo "🐋 Building Docker images..."
    # eval $(minikube docker-env -p kw-stack)

    echo "👉 Creating CouchDB secret..."
    kubectl create secret generic couchdb-secret --from-literal=username=admin --from-literal=password=admin
    echo "👉 Creating Gravitee secret..."
    kubectl create secret generic gravitee-secret --from-literal=username=admin --from-literal=password=admin

    echo "👉 Applying Kubernetes manifests..."
    echo "🛋   CouchDB"
    kubectl apply -f manifests/couchdb/couchdb-deployment.yaml
    kubectl apply -f manifests/couchdb/couchdb-ingress.yaml
    kubectl apply -f manifests/couchdb/couchdb-service.yaml
    echo "🔐  Keycloak"
    kubectl apply -f manifests/keycloak/keycloak-deployment.yaml
    kubectl apply -f manifests/keycloak/keycloak-ingress.yaml
    kubectl apply -f manifests/keycloak/keycloak-service.yaml
    echo "🪐  Gravitee"
    # kubectl apply -f manifests/gravitee/gravitee-api-deployment.yaml
    # kubectl apply -f manifests/gravitee/gravitee-ui-deployment.yaml
    # kubectl apply -f manifests/gravitee/gravitee-gateway-deployment.yaml
    # kubectl apply -f manifests/gravitee/gravitee-portal-deployment.yaml
    # kubectl apply -f manifests/gravitee/gravitee-api-service.yaml
    # kubectl apply -f manifests/gravitee/gravitee-ui-service.yaml
    # kubectl apply -f manifests/gravitee/gravitee-gateway-service.yaml
    # kubectl apply -f manifests/gravitee/gravitee-portal-service.yaml
    # kubectl apply -f manifests/gravitee/gravitee-ingress.yaml
    # kubectl apply -f manifests/gravitee/gravitee-configmap.yaml
    # echo "🔎  Elasticsearch"
    # kubectl apply -f manifests/elasticsearch/elasticsearch-deployment.yaml
    # kubectl apply -f manifests/elasticsearch/elasticsearch-service.yaml
    echo "⚙️   NestJS"
    kubectl apply -f manifests/nestjs/nestjs-deployment.yaml
    kubectl apply -f manifests/nestjs/nestjs-ingress.yaml
    kubectl apply -f manifests/nestjs/nestjs-service.yaml
    echo "⚛️   ReactJS"
    kubectl apply -f manifests/reactjs/reactjs-deployment.yaml
    kubectl apply -f manifests/reactjs/reactjs-ingress.yaml
    kubectl apply -f manifests/reactjs/reactjs-service.yaml

    echo "👉 Applying Kubernetes job to initialize CouchDB..."
    kubectl apply -f jobs/couchdb-init.yaml

    update_hosts
    echo "👉 Cluster created and applications deployed."
    ;;
  delete)
    echo "👉 Stopping and deleting Minikube cluster..."
    minikube stop -p kw-stack -v 5
    minikube delete -p kw-stack -v 5
    echo "👉 Cluster deleted."
    ;;
  stop)
    echo "👉 Stopping Minikube cluster..."
    minikube stop -p kw-stack -v 5
    echo "👉 Cluster stopped."
    ;;
  start)
    echo "👉 Starting Minikube cluster..."
    minikube start -p kw-stack -v 5
    update_hosts
    echo "👉 Cluster started."
    ;;
  access)
    print_urls_and_credentials
    ;;
  *)
    echo "👉 Usage: $0 {create|delete|stop|start|access}"
    exit 1
    ;;
esac
