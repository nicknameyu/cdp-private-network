#!/bin/bash

cp /tmp/named.conf /etc/bind/named.conf
cp /tmp/named.conf.options /etc/bind/named.conf.options


chown root:bind /etc/bind/named.conf
chown root:bind /etc/bind/named.conf.options
chmod 644 /etc/bind/named.conf
chmod 644 /etc/bind/named.conf.options
systemctl restart bind9.service
