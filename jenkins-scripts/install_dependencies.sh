#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "🚀 Starting installation of required dependencies..."

# Update package lists
sudo apt-get update -y
sudo apt-get upgrade -y

# Install Required Packages
sudo apt-get install -y curl wget unzip software-properties-common apt-transport-https ca-certificates gnupg2

echo "✅ Basic utilities installed."

# ----------------------------- Install Git -----------------------------
if ! command -v git &> /dev/null; then
    echo "📥 Installing Git..."
    sudo apt-get install -y git
    echo "✅ Git installed."
else
    echo "✅ Git is already installed."
fi

# ----------------------------- Install Java (OpenJDK 11) -----------------------------
if ! command -v java &> /dev/null; then
    echo "📥 Installing Java..."
    sudo apt-get install -y openjdk-11-jdk
    echo "✅ Java installed."
else
    echo "✅ Java is already installed."
fi

# ----------------------------- Install Maven -----------------------------
if ! command -v mvn &> /dev/null; then
    echo "📥 Installing Maven..."
    sudo apt-get install -y maven
    echo "✅ Maven installed."
else
    echo "✅ Maven is already installed."
fi

# ----------------------------- Install Docker -----------------------------
if ! command -v docker &> /dev/null; then
    echo "📥 Installing Docker..."
    sudo apt-get install -y docker.io
    sudo systemctl enable docker
    sudo systemctl start docker
    sudo usermod -aG docker $USER
    echo "✅ Docker installed."
else
    echo "✅ Docker is already installed."
fi

# ----------------------------- Install AWS CLI -----------------------------
if ! command -v aws &> /dev/null; then
    echo "📥 Installing AWS CLI..."
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
    rm -rf awscliv2.zip aws
    echo "✅ AWS CLI installed."
else
    echo "✅ AWS CLI is already installed."
fi

# ----------------------------- Install Terraform -----------------------------
if ! command -v terraform &> /dev/null; then
    echo "📥 Installing Terraform..."
    wget -q -O - https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
    sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
    sudo apt-get update -y && sudo apt-get install -y terraform
    echo "✅ Terraform installed."
else
    echo "✅ Terraform is already installed."
fi

# ----------------------------- Install Ansible -----------------------------
if ! command -v ansible &> /dev/null; then
    echo "📥 Installing Ansible..."
    sudo apt-add-repository --yes --update ppa:ansible/ansible
    sudo apt-get install -y ansible
    echo "✅ Ansible installed."
else
    echo "✅ Ansible is already installed."
fi

# ----------------------------- Install kubectl -----------------------------
if ! command -v kubectl &> /dev/null; then
    echo "📥 Installing kubectl..."
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x kubectl
    sudo mv kubectl /usr/local/bin/
    echo "✅ kubectl installed."
else
    echo "✅ kubectl is already installed."
fi

# ----------------------------- Install Minikube -----------------------------
if ! command -v minikube &> /dev/null; then
    echo "📥 Installing Minikube..."
    curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
    chmod +x minikube
    sudo mv minikube /usr/local/bin/
    echo "✅ Minikube installed."
else
    echo "✅ Minikube is already installed."
fi

# ----------------------------- Final Cleanup -----------------------------
echo "🧹 Cleaning up..."
sudo apt-get autoremove -y
sudo apt-get clean -y

echo "🎉 All dependencies installed successfully!"
