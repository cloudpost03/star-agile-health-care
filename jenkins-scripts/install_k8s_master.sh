#!/bin/bash
echo "Setting up Kubernetes Master Node..."

echo "Updating system and installing dependencies..."
sudo apt update -y
sudo apt install -y apt-transport-https ca-certificates curl

echo "Adding Kubernetes GPG Key..."
curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/kubernetes-archive-keyring.gpg

echo "Adding Kubernetes repo..."
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

echo "Installing kubeadm, kubelet, kubectl..."
sudo apt update -y
sudo apt install -y kubeadm kubelet kubectl
sudo systemctl enable kubelet && sudo systemctl start kubelet

echo "Disabling swap (required for Kubernetes)..."
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab

echo "Setting sysctl params for Kubernetes..."
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system

echo "Kubernetes Master Node setup complete!"

