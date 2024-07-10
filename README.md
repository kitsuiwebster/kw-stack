# kw-stack

This repository contains Kubernetes manifests and management scripts for deploying a stack with CouchDB, Keycloak, and Gravitee on a Minikube cluster.

## Prerequisites

Make sure you have the following tools installed on your machine:

- Minikube: [Installation Guide](https://minikube.sigs.k8s.io/docs/start/)
- kubectl: [Installation Guide](https://kubernetes.io/docs/tasks/tools/)
- K9s (optional): [Installation Guide](https://k9scli.io/topics/install/)

## Clone the Repository

To clone the repository, run:

```bash
git clone https://github.com/kitsuiwebster/kw-stack.git
cd kw-stack
```

## Managing the Minikube Cluster with Scripts

I have provided scripts to easily manage the Minikube cluster.

Ensure you have executable permissions for the scripts. If not, you can add permissions with:

```bash
chmod +x scripts/*.sh

```

### Create the Cluster

To create and start the Minikube cluster, run:

```bash
./scripts/create.sh

```

### Delete the Cluster

To stop and delete the Minikube cluster, run:

```bash
./scripts/delete.sh

```

### Pause the Cluster

To pause the Minikube cluster, run:

```bash
./scripts/pause.sh

```

### Resume the Cluster

To resume the Minikube cluster, run:

```bash
./scripts/resume.sh

```

### Use K9s to Manage the Cluster

To use K9s to manage the Minikube cluster, run:

```bash
k9s
```glpat-vwJTbXg7xcPX3JmbkcUZ
