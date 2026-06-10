#!/usr/bin/env bash

echo "################ DNS Configuration ##################"
apt install -y bind9 dnsutils

# --- Configuration ---
DNS_RESOLVER_IP="__DNS_RESOLVER_IP__"
REGION="__REGION__"

# --- Write named.conf.options ---
cat > /etc/bind/named.conf.options << 'EOF'
// Customized Private DNS
options {
  directory "/var/cache/bind";
  forwarders { 169.254.169.253; };
  dnssec-validation yes;
  listen-on-v6 { any; };
  allow-query { any; };
};
EOF

# --- Write named.conf ---
cat > /etc/bind/named.conf << EOF
include "/etc/bind/named.conf.options";
include "/etc/bind/named.conf.local";
include "/etc/bind/named.conf.default-zones";

zone "efs.${REGION}.amazonaws.com" {
    type forward;
    forward only;
    forwarders { ${DNS_RESOLVER_IP}; };
};
EOF

systemctl restart bind9.service
