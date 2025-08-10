#!/bin/bash

# Execução como root
apt update 
apt install sudo
# Adcionando usuario ao grupo de adm
usermod -aG sudo kaeu

# Baixando a CLI do K8s pelo curl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/arm64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
# Verifique com
kubectl version --client
