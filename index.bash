#!/bin/bash

COMMAND=$1

update_hosts() {
  echo "\n👉 Get the new Minikube IP"
  MINIKUBE_IP=$(minikube ip -p kw-stack -v 5)

  echo "\n👉 Define the hostnames"
  HOSTNAMES=("couchdb.local" "gravitee.local" "keycloak.local" "nestjs.local" "reactjs.local")

  echo "\n👉 Backup the original /etc/hosts file"
  sudo cp /etc/hosts /etc/hosts.bak

  echo "\n👉 Remove old Minikube entries"
  for HOST in "${HOSTNAMES[@]}"; do
    sudo sed -i "/$HOST/d" /etc/hosts
  done

  echo "\n👉 Add new Minikube entries"
  for HOST in "${HOSTNAMES[@]}"; do
    echo "\n$MINIKUBE_IP $HOST" | sudo tee -a /etc/hosts
  done

  echo "\n👉 Updated /etc/hosts with new Minikube IP: $MINIKUBE_IP"
}

wait_for_ingress() {
  echo "\n👉 Waiting for NGINX Ingress controller to be ready..."
  while ! kubectl get pods -n ingress-nginx | grep -q '1/1'; do
    echo "\n👉 NGINX Ingress controller is not ready yet. Waiting..."
    sleep 5
  done
  echo "\n👉 NGINX Ingress controller is ready."
}

print_urls_and_credentials() {
  MINIKUBE_IP=$(minikube ip -p kw-stack -v 5)
  echo "\n👉 Access your services at the following URLs:"
  echo "\n\n🛋   CouchDB: http://couchdb.local/_utils"
  echo "\n🆔  admin"
  echo "\n🗝️   admin"
  echo "\n\n🪐  Gravitee: http://gravitee.local"
  echo "\n🆔  admin"
  echo "\n🗝️   admin"
  echo "\n\n🔐  Keycloak: http://keycloak.local"
  echo "\n🆔  admin"
  echo "\n🗝️   admin"
  echo "\n\n⚙️   NestJS: http://nestjs.local"
  echo "\n\n⚛️   ReactJS: http://reactjs.local"
}

case $COMMAND in
  create)
    echo "\n👉 Starting Minikube..."
    minikube start --cpus=4 -p kw-stack -v 5
    echo "\n👉 Enabling NGINX Ingress controller..."
    minikube addons enable ingress -p kw-stack -v 5
    echo "\n👉 Deleting ValidatingWebhookConfiguration to bypass NGINX Ingress admission rules..."
    kubectl delete -A ValidatingWebhookConfiguration ingress-nginx-admission
    echo "\n👉 Setting kubectl context to minikube..."
    kubectl config use-context kw-stack
    echo "\n👉 Waiting for NGINX Ingress controller to be ready..."
    wait_for_ingress
    echo "\n👉 Enabling snippet annotations in NGINX Ingress Controller..."
    kubectl get deployments -n ingress-nginx
    kubectl set env deployment/ingress-nginx-controller ENABLE_SNIPPET_ANNOTATIONS=true -n ingress-nginx

    echo "\n☸️ Adding Bitnami Helm repository..."
    helm repo update

    echo "\n⚛️   Building React app..."
    (cd reactjs-app && npm install && npm run build)

    echo "\n⚛️   Building React Docker image..."
    eval $(minikube docker-env -p kw-stack)
    docker build -t reactjs-app:latest ./reactjs-app

    echo "\n⚙️   Building NestJS app..."
    (cd nestjs-app && npm install && npm run build)

    echo "\n⚙️   Building NestJS Docker image..."
    eval $(minikube docker-env -p kw-stack)
    docker build -t nestjs-app:latest ./nestjs-app

    echo "\n🔐  Deploying Keycloak..."
    kubectl create -f https://raw.githubusercontent.com/keycloak/keycloak-quickstarts/latest/kubernetes/keycloak.yaml
    echo "\n🔐  Setting up Keycloak Ingress..."
    wget -q -O - https://raw.githubusercontent.com/keycloak/keycloak-quickstarts/latest/kubernetes/keycloak-ingress.yaml | \
    sed "s/KEYCLOAK_HOST/keycloak.local/" | \
    kubectl create -f -

    echo "\n🪐 Adding Gravitee Helm repository..."
    helm repo add graviteeio https://helm.gravitee.io

    echo "\n🪐 Creating a dedicated namespace for Gravitee..."
    kubectl create namespace gravitee-apim

    echo "\n🪐 Installing Gravitee..."
    helm install graviteeio-apim4x graviteeio/apim \
      --create-namespace \
      --namespace gravitee-apim \
      -f /home/ash/kitsui/kw-stack/manifests/gravitee/values.yaml \
      --set ingress.className=nginx \
      # --debug \
      # --set ingress.controller.ingressClassName=nginx \
      # --set apim.ingress.annotations."nginx\.ingress\.kubernetes\.io/configuration-snippet"=null

    echo "\n🪐 List of Gravitee Helm releases:"
    helm list -n gravitee-apim

    # echo "\n🪐 Updating /etc/hosts for Gravitee services..."
    # MINIKUBE_IP=$(minikube ip -p kw-stack -v 5)
    # echo "\n$MINIKUBE_IP management-api.local" | sudo tee -a /etc/hosts
    # echo "\n$MINIKUBE_IP gateway.local" | sudo tee -a /etc/hosts
    # echo "\n$MINIKUBE_IP portal.local" | sudo tee -a /etc/hosts
    # echo "\n$MINIKUBE_IP management-ui.local" | sudo tee -a /etc/hosts

    echo "\n🔑 Creating CouchDB secret..."
    kubectl create secret generic couchdb-secret --from-literal=username=admin --from-literal=password=admin
    echo "\n🔑 Creating Gravitee secret..."
    kubectl create secret generic gravitee-secret --from-literal=username=admin --from-literal=password=admin

    echo "\n👉 Applying Kubernetes manifests..."
    echo "\n🛋   CouchDB"
    kubectl apply -f manifests/couchdb/couchdb-deployment.yaml
    kubectl apply -f manifests/couchdb/couchdb-ingress.yaml
    kubectl apply -f manifests/couchdb/couchdb-service.yaml

    echo "\n⚙️   NestJS"
    kubectl apply -f manifests/nestjs/nestjs-deployment.yaml
    kubectl apply -f manifests/nestjs/nestjs-ingress.yaml
    kubectl apply -f manifests/nestjs/nestjs-service.yaml
    echo "\n⚛️   ReactJS"
    kubectl apply -f manifests/reactjs/reactjs-deployment.yaml
    kubectl apply -f manifests/reactjs/reactjs-ingress.yaml
    kubectl apply -f manifests/reactjs/reactjs-service.yaml

    echo "\n👉 Applying Kubernetes job to initialize CouchDB..."
    kubectl apply -f jobs/couchdb-init.yaml

    echo "\n🪐 Update Gravitee Helm chart"
    helm dependency update graviteeio/apim

    update_hosts
    echo "\n👉 Cluster created and applications deployed."
    ;;
  delete)
    echo "\n👉 Stopping and deleting Minikube cluster..."
    minikube stop -p kw-stack -v 5
    minikube delete -p kw-stack -v 5
    echo "\n👉 Cluster deleted."
    ;;
  stop)
    echo "\n👉 Stopping Minikube cluster..."
    minikube stop -p kw-stack -v 5
    echo "\n👉 Cluster stopped."
    ;;
  start)
    echo "\n👉 Starting Minikube cluster..."
    minikube start -p kw-stack -v 5
    update_hosts
    echo "\n👉 Cluster started."
    ;;
  access)
    print_urls_and_credentials
    ;;
  *)
    echo "\n👉 Usage: $0 {create|delete|stop|start|access}"
    exit 1
    ;;
esac
