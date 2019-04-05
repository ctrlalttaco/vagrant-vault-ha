#!/usr/bin/env bash

# Dnsmasq configuration
DNS_IP=$(grep nameserver /etc/resolv.conf | awk '{ print $2 }')
echo "server=$DNS_IP" | tee /etc/dnsmasq.d/00-default
echo 'server=/consul/127.0.0.1#8600' | tee /etc/dnsmasq.d/10-consul
sed -i '/^nameserver.*$/d' /etc/resolv.conf
echo 'nameserver 127.0.0.1' | tee -a /etc/resolv.conf

systemctl enable dnsmasq
systemctl start dnsmasq