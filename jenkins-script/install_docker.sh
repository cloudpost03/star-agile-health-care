#!/bin/bash
echo "Installing Docker..."
sudo apt update -y
sudo apt install -y docker.io
sudo systemctl start docker
sudo systemctl enable docker

