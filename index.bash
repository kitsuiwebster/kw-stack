#!/bin/bash

COMMAND=$1

source ./ascii-arts/index.bash

update_hosts() {
  echo -e "\n👉 Get the new Minikube IP"
  MINIKUBE_IP=$(minikube ip -p kw-stack -v 5)

  echo -e "\n👉 Define the hostnames"
  HOSTNAMES=("couchdb.pikapi.co" "pikapi.co" "keycloak.pikapi.co" "nest.pikapi.co")

  echo -e "\n👉 Backup the original /etc/hosts file"
  sudo cp /etc/hosts /etc/hosts.bak

  echo -e "\n👉 Remove old Minikube entries"
  for HOST in "${HOSTNAMES[@]}"; do
    sudo sed -i "/$HOST/d" /etc/hosts
  done

  echo -e "\n👉 Add new Minikube entries"
  for HOST in "${HOSTNAMES[@]}"; do
    echo -e "$MINIKUBE_IP $HOST" | sudo tee -a /etc/hosts
  done

  echo -e "\n👉 Updated /etc/hosts with new Minikube IP: $MINIKUBE_IP"
}

wait_for_ingress() {
  echo -e "\n👉 Waiting for NGINX Ingress controller to be ready..."
  while ! kubectl get pods -n ingress-nginx | grep -q '1/1'; do
    echo -e "\n👉 NGINX Ingress controller is not ready yet. Waiting..."
    sleep 60
  done
  echo -e "\n👉 NGINX Ingress controller is ready."
}

print_urls_and_credentials() {
  MINIKUBE_IP=$(minikube ip -p kw-stack -v 5)
  echo -e "\n👉 Access your services at the following URLs:"
  echo -e "\n\n🛋   CouchDB: http://couchdb.pikapi.co/_utils"
  echo -e "\n🆔  admin"
  echo -e "🗝️   admin"
  echo -e "\n\n🪐  Gravitee:"
  echo -e "\n🪐  Management API: http://apim-api.pikapi.co/management"
  echo -e "\n🪐  Management UI: http://apim-ui.pikapi.co/console"
  echo -e "\n🆔  admin"
  echo -e "🗝️   admin"
  echo -e "\n🪐  Portal: http://apim-portal.pikapi.co"
  echo -e "\n🪐  Gateway: http://apim-gateway.pikapi.co"
  echo -e "\n🪐  API Portal: http://apim-apiportal.pikapi.co/portal"
  echo -e "\n\n🔐  Keycloak: http://keycloak.pikapi.co"
  echo -e "\n🆔  admin"
  echo -e "🗝️   admin"
  echo -e "\n\n⚙️   NestJS: http://nest.pikapi.co"
  echo -e "\n\n⚛️   ReactJS: http://pikapi.co"
}

case $COMMAND in
  create)
    echo -e "\n👉 Setting vm.max_map_count to 262144..."
    sudo sysctl -w vm.max_map_count=262144
    echo -e "\n👉 Starting Minikube..."
    minikube start --cpus=2 -p kw-stack --memory=2048 -v 5
    echo -e "\n👉 Enabling NGINX Ingress controller..."
    minikube addons enable ingress -p kw-stack -v 5
    echo -e "\n👉 Deleting ValidatingWebhookConfiguration to bypass NGINX Ingress admission rules..."
    kubectl delete -A ValidatingWebhookConfiguration ingress-nginx-admission
    echo -e "\n👉 Setting kubectl context to minikube..."
    kubectl config use-context kw-stack
    wait_for_ingress
    echo -e "\n👉 Enabling snippet annotations in NGINX Ingress Controller..."
    kubectl get deployments -n ingress-nginx
    kubectl set env deployment/ingress-nginx-controller ENABLE_SNIPPET_ANNOTATIONS=true -n ingress-nginx

    echo -e "\n☸️ Adding Bitnami Helm repository..."
    helm repo update

    echo -e "\n🔑 Installing cert-manager..."
    kubectl create namespace cert-manager/config-map
    helm repo add jetstack https://charts.jetstack.io
    helm repo update
    helm install cert-manager jetstack/cert-manager \
      --namespace cert-manager \
      --version v1.6.0 \
      --set installCRDs=true
    echo -e "\n🔑 Applying cluster issuer"
    kubectl apply -f letsencrypt/cluster-issuer.yaml
    kubectl describe certificate -n default

    couchdb_ascii

    echo -e "\n🛋   Applying CouchDB manifests..."
    kubectl apply -f manifests/couchdb/couchdb-deployment.yaml
    kubectl apply -f manifests/couchdb/couchdb-ingress.yaml
    kubectl apply -f manifests/couchdb/couchdb-service.yaml

    echo -e "\n🛋   Applying Kubernetes job to initialize CouchDB..."
    kubectl apply -f jobs/couchdb-init.yaml

    echo -e "\n🔑 Creating CouchDB secret..."
    kubectl create secret generic couchdb-secret --from-literal=username=admin --from-literal=password=admin

    react_ascii

    echo -e "\n⚛️   Building React app..."
    (cd reactjs-app && npm install && npm run build)

    echo -e "\n⚛️   Building React Docker image..."
    eval $(minikube docker-env -p kw-stack)
    docker build -t reactjs-app:latest ./reactjs-app

    echo -e "\n⚛️   Applying React manifests..."
    kubectl apply -f manifests/reactjs/reactjs-deployment.yaml
    kubectl apply -f manifests/reactjs/reactjs-ingress.yaml
    kubectl apply -f manifests/reactjs/reactjs-service.yaml

    nest_ascii

    echo -e "\n⚙️   Building NestJS app..."
    (cd nestjs-app && npm install && npm run build)

    echo -e "\n⚙️   Building NestJS Docker image..."
    eval $(minikube docker-env -p kw-stack)
    docker build -t nestjs-app:latest ./nestjs-app

    echo -e "\n⚙️   Applying NestJS manifests..."
    kubectl apply -f manifests/nestjs/nestjs-deployment.yaml
    kubectl apply -f manifests/nestjs/nestjs-ingress.yaml
    kubectl apply -f manifests/nestjs/nestjs-service.yaml

    keycloak_ascii

    echo -e "\n🔐  Deploying Keycloak..."
    kubectl create -f https://raw.githubusercontent.com/keycloak/keycloak-quickstarts/latest/kubernetes/keycloak.yaml
    echo -e "\n🔐  Setting up Keycloak Ingress..."
    wget -q -O - https://raw.githubusercontent.com/keycloak/keycloak-quickstarts/latest/kubernetes/keycloak-ingress.yaml | \
    kubectl apply -f -

    gravitee_ascii

    echo -e "\n🪐 Adding Gravitee Helm repository..."
    helm repo add graviteeio https://helm.gravitee.io

    echo -e "\n🪐 Creating a dedicated namespace for Gravitee..."
    kubectl create namespace gravitee-apim

    echo -e "\n🪐 Installing Gravitee..."
    helm install graviteeio-apim4x graviteeio/apim \
      -f /home/ash/kitsui/kw-stack/manifests/gravitee/values.yaml \
      --set ingress.className=nginx \
      # --debug \

    echo -e "\n🪐 List of Gravitee Helm releases:"
    helm list -n gravitee-apim

    echo -e "\n🔑 Creating Gravitee secret..."
    kubectl create secret generic gravitee-secret --from-literal=username=admin --from-literal=password=admin

    echo -e "\n🪐 Update Gravitee Helm chart"
    helm dependency update graviteeio/apim

    update_hosts
    echo -e "\n👉 Cluster created and applications deployed."

    print_urls_and_credentials
    ;;
  delete)
    echo -e "\n👉 Stopping and deleting Minikube cluster..."
    minikube stop -p kw-stack -v 5
    minikube delete -p kw-stack -v 5
    echo -e "\n👉 Cluster deleted."
    ;;
  stop)
    echo -e "\n👉 Stopping Minikube cluster..."
    minikube stop -p kw-stack -v 5
    echo -e "\n👉 Cluster stopped."
    ;;
  start)
    echo -e "\n👉 Setting vm.max_map_count to 262144..."
    sudo sysctl -w vm.max_map_count=262144
    echo -e "\n👉 Starting Minikube cluster..."
    minikube start -p kw-stack -v 5
    update_hosts
    echo -e "\n👉 Cluster started."
    ;;
  access)
    print_urls_and_credentials
    ;;
  install)
    echo "👉  Install Minikube"
    curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
    sudo install minikube-linux-amd64 /usr/local/bin/minikube
    rm minikube-linux-amd64
    sudo apt install virtualbox virtualbox-ext-pack -y
    sudo usermod -aG vboxusers $USER

    echo "👉  Install Docker"
    sudo apt install docker.io -y
    sudo systemctl start docker
    sudo systemctl enable docker
    sudo usermod -aG docker $USER
    newgrp docker

    echo "👉  Install Kubectl"
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
    echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check
    if [ $? -eq 0 ]; then
        sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
        rm kubectl kubectl.sha256
    else
        echo "kubectl checksum verification failed!"
        exit 1
    fi

    echo "👉  Install k9s"
    K9S_VERSION=$(curl -s https://api.github.com/repos/derailed/k9s/releases/latest | grep tag_name | cut -d '"' -f 4)
    wget https://github.com/derailed/k9s/releases/download/$K9S_VERSION/k9s_Linux_amd64.tar.gz
    tar -xvzf k9s_Linux_amd64.tar.gz
    sudo mv k9s /usr/local/bin/
    rm k9s_Linux_amd64.tar.gz

    echo "👉  Install Helm"
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    helm version
    ;;
  *)
    echo -e "\n👉 Usage: $0 {create|delete|stop|start|access}"
    exit 1
    ;;
esac
