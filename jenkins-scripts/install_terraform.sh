#!/bin/bash
echo "Installing Terraform..."
wget -O terraform.zip https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
unzip terraform.zip
sudo mv terraform /usr/local/bin/

