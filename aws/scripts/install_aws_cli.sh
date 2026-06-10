#!/bin/bash
set -euo pipefail
 
# AWS CLI v2 Installer for Linux (x86_64)
 
echo "==> Installing dependencies..."
sudo apt-get update -y
sudo apt-get install -y unzip curl
 
echo "==> Downloading AWS CLI v2..."
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
 
echo "==> Unzipping..."
unzip -o awscliv2.zip
 
echo "==> Installing AWS CLI..."
if aws --version &>/dev/null; then
  echo "    AWS CLI already installed — updating..."
  sudo ./aws/install --update
else
  sudo ./aws/install
fi
 
echo "==> Cleaning up..."
rm -rf awscliv2.zip aws/
 
echo "==> Done!"
aws --version
