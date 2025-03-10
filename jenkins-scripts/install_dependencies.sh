#!/bin/bash

echo "🚀 Starting installation of required dependencies..."

# Remove the existing Kubernetes repo file (if any)
sudo rm -f /etc/apt/sources.list.d/kubernetes.list

# Add the correct Kubernetes repository
sudo apt-get update -y
sudo apt-get install -y apt-transport-https ca-certificates curl

# Add Kubernetes signing key
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo tee /etc/apt/keyrings/kubernetes-apt-keyring.asc >/dev/null

# Add the correct repository for Ubuntu 22.04 (Jammy)
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.asc] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list

# Update package lists and install Kubernetes tools
sudo apt-get update -y
sudo apt-get install -y kubectl kubelet kubeadm

echo "✅ Kubernetes tools installed successfully!"
