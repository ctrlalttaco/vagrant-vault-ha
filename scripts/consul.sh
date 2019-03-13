#!/usr/bin/env bash

export PATH="$PATH:/usr/local/bin"

CONSUL_VERSION="${CONSUL_VERSION:-1.4.3}"
CONSUL_ENTERPRISE="${CONSUL_ENTERPRISE:-false}"
CONSUL_TYPE="${CONSUL_TYPE:-server}"
CONSUL_ACL="${CONSUL_ACL:-false}"

echo "Installing dependencies ..."
yum -y makecache
yum -y install unzip curl dnsmasq net-tools bind-utils

echo "Installing Consul version ${CONSUL_VERSION}..."
if [ $CONSUL_ENTERPRISE == "true" ]
then
    CONSUL_VERSION="${CONSUL_VERSION}+ent"
fi

CONSUL_URL="https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_linux_amd64.zip"

curl -s -o consul.zip "$CONSUL_URL"

unzip consul.zip
chown root:root consul
chmod 0755 consul
mv consul /usr/local/bin

consul -autocomplete-install
complete -C /usr/local/bin/consul consul

echo "Creating Consul service account ..."
useradd -r -d /etc/consul -s /bin/false consul

echo "Creating Consul directory structure ..."
mkdir -p /etc/consul/{config.d,pki}
chown -R root:consul /etc/consul
chmod -R 0750 /etc/consul

mkdir /var/{lib,log}/consul
chown consul:consul /var/{lib,log}/consul
chmod 0750 /var/{lib,log}/consul

echo "Copy PKI certificates ..."
cp /vagrant/pki/${CONSUL_TYPE}{,-key}.pem /etc/consul/pki
cp /vagrant/pki/ca.pem /etc/consul/pki
chown root:consul /etc/consul/pki/*
chmod 0640 /etc/consul/pki/*

echo "Creating Consul config ..."
NETWORK_INTERFACE=$(ls -1 /sys/class/net | grep -v lo | sort -r | head -n 1)
IP_ADDRESS=$(ip address show $NETWORK_INTERFACE | awk '{print $2}' | egrep -o '([0-9]+\.){3}[0-9]+')
HOSTNAME=$(hostname -s)


cat > /etc/consul/config.d/consul.hcl << EOF
# /etc/consul/config.d/consul.hcl
datacenter              = "vagrant"
node_name               = "${HOSTNAME}"
data_dir                = "/var/lib/consul"
log_file                = "/var/log/consul/consul.log"
ui                      = true
advertise_addr          = "${IP_ADDRESS}"
retry_join              = ["172.20.0.11", "172.20.0.12", "172.20.0.13"]
encrypt                 = "3Zp3zLg7eQNA9p+asQhU8A=="
encrypt_verify_incoming = true
encrypt_verify_outgoing = true
ca_file                 = "/etc/consul/pki/ca.pem"
cert_file               = "/etc/consul/pki/${CONSUL_TYPE}.pem"
key_file                = "/etc/consul/pki/${CONSUL_TYPE}-key.pem"
verify_incoming         = true
verify_outgoing         = true
verify_server_hostname  = true

performance {
  raft_multiplier = 1
}
EOF

# Server configuration
if [ $CONSUL_TYPE == "server" ]
then
    cat > /etc/consul/config.d/server.hcl << EOF
# /etc/consul/config.d/server.hcl
server           = true
bootstrap_expect = 3

# Bind HTTP to 127.0.0.1:8500
# Bind HTTPS to ${IP_ADDRESS}:8500
addresses {
    https = "${IP_ADDRESS}"
}

ports {
    https = 8500
}
EOF
fi

# ACL configuration
if [ $CONSUL_ACL == "true" ]
then
    cat > /etc/consul/config.d/acl.hcl << EOF
acl {
    enabled = true
    default_policy = "deny"
    down_policy = "extend-cache"

    # tokens {
    #     agent = "ACL_TOKEN"
    #     master = "MASTER_ACL_TOKEN"
    # }
}
EOF
fi

chown root:consul /etc/consul/config.d/*
chmod 0640 /etc/consul/config.d/*

# Systemd configuration
echo "Configuring Consul service..."
cat > /etc/systemd/system/consul.service << EOF
[Unit]
Description="HashiCorp Consul - A service mesh solution"
Documentation=https://www.consul.io/
Requires=network-online.target
After=network-online.target
ConditionFileNotEmpty=/etc/consul/config.d/consul.hcl

[Service]
User=consul
Group=consul
ExecStart=/usr/local/bin/consul agent -config-dir=/etc/consul/config.d
ExecReload=/usr/local/bin/consul reload
KillMode=process
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable consul
systemctl restart consul

# Dnsmasq configuration
DNS_IP=$(grep nameserver /etc/resolv.conf | awk '{ print $2 }')
echo "server=$DNS_IP" | tee /etc/dnsmasq.d/00-default
echo 'server=/consul/127.0.0.1#8600' | tee /etc/dnsmasq.d/10-consul
sed -i '/^nameserver.*$/d' /etc/resolv.conf
echo 'nameserver 127.0.0.1' | tee -a /etc/resolv.conf

systemctl enable dnsmasq
systemctl start dnsmasq