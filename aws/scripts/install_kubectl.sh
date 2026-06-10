#!/usr/bin/env bash
# install_kubectl.sh — Download and install kubectl on Ubuntu
# Source: Amazon EKS 1.35.3 (2026-04-08)
 
set -euo pipefail
 
KUBECTL_URL="https://s3.us-west-2.amazonaws.com/amazon-eks/1.35.3/2026-04-08/bin/linux/amd64/kubectl"
INSTALL_DIR="/usr/local/bin"
BINARY="${INSTALL_DIR}/kubectl"
 
# ── Preflight ────────────────────────────────────────────────────────────────
if [[ "$(id -u)" -ne 0 ]]; then
  echo "ERROR: This script must be run as root (or via sudo)." >&2
  exit 1
fi
 
if ! command -v curl &>/dev/null; then
  echo "curl not found — installing..."
  apt-get update -qq && apt-get install -y -qq curl
fi
 
# ── Download ─────────────────────────────────────────────────────────────────
echo "Downloading kubectl from Amazon EKS..."
curl -fSL --progress-bar -o /tmp/kubectl "${KUBECTL_URL}"
 
# ── Install ──────────────────────────────────────────────────────────────────
echo "Installing kubectl to ${BINARY}..."
mv /tmp/kubectl "${BINARY}"
chmod a+x "${BINARY}"          # rwxr-xr-x — execute for all users
 
# ── Verify ───────────────────────────────────────────────────────────────────
echo ""
echo "Installation complete."
echo "  Path    : ${BINARY}"
echo "  Version : $(kubectl version --client --short 2>/dev/null || kubectl version --client)"
 