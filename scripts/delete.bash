#!/bin/bash

echo "Stopping and deleting Minikube cluster..."
minikube stop
minikube delete

echo "Cluster deleted."
