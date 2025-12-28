#!/bin/bash
# cloud init runs as root user
#set -ex # exit on error
echo Start upgrading repoistory ..... >> /tmp/user_data.log 2>&1
apt update -y >> /tmp/user_data.log 2>&1
apt upgrade -y >> /tmp/user_data.log 2>&1
echo Completed upgrading repoistory . >> /tmp/user_data.log 2>&1

echo Start installing DNS packages >> /tmp/user_data.log 2>&1
apt install bind9 -y  >> /tmp/user_data.log 2>&1
apt install dnsutils -y  >> /tmp/user_data.log 2>&1
echo Completed installing DNS packages >> /tmp/user_data.log 2>&1

echo Start installing Azure CLI >> /tmp/user_data.log 2>&1
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash >> /tmp/user_data.log 2>&1
az aks install-cli >> /tmp/user_data.log 2>&1

echo Completed installing Azure CLI >> /tmp/user_data.log 2>&1
