#!/usr/bin/env bash

export PATH=$PATH:/usr/local/bin

VAULT_VERSION="${VAULT_VERSION:-1.1.0}"
ENTERPRISE="${ENTERPRISE:false}"

echo "Installing Vault version ${VAULT_VERSION}..."
if [ $ENTERPRISE == "true" ]
then
  cp /vagrant/vault-enterprise_*.zip ./vault.zip
else
  VAULT_URL="https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_linux_amd64.zip"
  curl -s -o vault.zip "$VAULT_URL"
fi

unzip vault.zip
chown root:root vault
chmod 0755 vault
mv vault /usr/local/bin

vault -autocomplete-install
complete -C /usr/local/bin/vault vault
setcap cap_ipc_lock=+ep /usr/local/bin/vault

echo "Creating Vault service account ..."
useradd -r -d /etc/vault -s /bin/false vault

echo "Creating directory structure ..."
mkdir -p /etc/vault/pki
chown -R root:vault /etc/vault
chmod -R 0750 /etc/vault

mkdir /var/{lib,log}/vault
chown vault:vault /var/{lib,log}/vault
chmod 0750 /var/{lib,log}/vault

echo "Copy PKI certificates ..."
cp /vagrant/pki/vault{,-key}.pem /etc/vault/pki
cp /vagrant/pki/ca.pem /etc/vault/pki
cat /etc/vault/pki/vault.pem | tee -a /etc/vault/pki/vault-chain.pem
cat /etc/vault/pki/ca.pem | tee -a /etc/vault/pki/vault-chain.pem
chown root:vault /etc/vault/pki/*
chmod 0640 /etc/vault/pki/*

echo "Creating Vault configuration ..."
echo 'export VAULT_ADDR="http://localhost:8200"' | tee /etc/profile.d/vault.sh

NETWORK_INTERFACE=$(ls -1 /sys/class/net | grep -v lo | sort -r | head -n 1)
IP_ADDRESS=$(ip address show $NETWORK_INTERFACE | awk '{print $2}' | egrep -o '([0-9]+\.){3}[0-9]+')
HOSTNAME=$(hostname -s)

tee /etc/vault/vault.hcl << EOF
api_addr = "https://${IP_ADDRESS}:8200"
ui = true

storage "consul" {
  # token = "<ACL Token>"
}

listener "tcp" {
  address     = "127.0.0.1:8200"
  tls_disable = true
}

listener "tcp" {
  address       = "${IP_ADDRESS}:8200"
  tls_key_file  = "/etc/vault/pki/vault-key.pem"
  tls_cert_file = "/etc/vault/pki/vault-chain.pem"
}
EOF

chown root:vault /etc/vault/vault.hcl
chmod 0640 /etc/vault/vault.hcl

tee /etc/systemd/system/vault.service << EOF
[Unit]
Description="HashiCorp Vault - A tool for managing secrets"
Documentation=https://www.vaultproject.io/docs/
Requires=network-online.target
After=network-online.target
ConditionFileNotEmpty=/etc/vault/vault.hcl

[Service]
User=vault
Group=vault
ProtectSystem=full
ProtectHome=read-only
PrivateTmp=yes
PrivateDevices=yes
SecureBits=keep-caps
AmbientCapabilities=CAP_IPC_LOCK
CapabilityBoundingSet=CAP_SYSLOG CAP_IPC_LOCK
NoNewPrivileges=yes
ExecStart=/usr/local/bin/vault server -config=/etc/vault/vault.hcl
ExecReload=/bin/kill --signal HUP \$MAINPID
KillMode=process
KillSignal=SIGINT
Restart=on-failure
RestartSec=5
TimeoutStopSec=30
StartLimitInterval=60
StartLimitBurst=3

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable vault
systemctl restart vault
