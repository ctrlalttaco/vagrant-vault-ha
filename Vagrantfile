# -*- mode: ruby -*-
# vi: set ft=ruby :

### Define environment variables to pass on to provisioner

# Use Enterprise binaries
ENTERPRISE = ENV['ENTERPRISE'] || "false"

# Specify if Consul ACL should be enabled
CONSUL_ACL = ENV['CONSUL_ACL'] || "false"

# Specify a Consul version
CONSUL_VERSION = ENV['CONSUL_VERSION'] || "1.4.4"

# Specify a Vault version
VAULT_VERSION = ENV['VAULT_VERSION'] || "1.1.0"

### Vagrant box definitions

# Vagrantfile API/syntax version.
# NB: Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "ubuntu/bionic64"

  config.vm.define "consul1" do |c1|
      c1.vm.hostname = "c1"
      c1.vm.network "private_network", ip: "10.100.0.11"
      c1.vm.provision "shell",
          path: "scripts/consul.sh",
          env: {
              'CONSUL_VERSION' => CONSUL_VERSION,
              'ENTERPRISE' => ENTERPRISE,
              'CONSUL_ACL' => CONSUL_ACL
          }
  end

  config.vm.define "consul2" do |c2|
      c2.vm.hostname = "c2"
      c2.vm.network "private_network", ip: "10.100.0.12"
      c2.vm.provision "shell",
          path: "scripts/consul.sh",
          env: {
              'CONSUL_VERSION' => CONSUL_VERSION,
              'ENTERPRISE' => ENTERPRISE,
              'CONSUL_ACL' => CONSUL_ACL
          }
  end

  config.vm.define "consul3" do |c3|
      c3.vm.hostname = "c3"
      c3.vm.network "private_network", ip: "10.100.0.13"
      c3.vm.provision "shell",
          path: "scripts/consul.sh",
          env: {
              'CONSUL_VERSION' => CONSUL_VERSION,
              'ENTERPRISE' => ENTERPRISE,
              'CONSUL_ACL' => CONSUL_ACL
          }
  end

  config.vm.define "vault1" do |v1|
      v1.vm.hostname = "v1"
      v1.vm.network "private_network", ip: "10.100.1.11"
      v1.vm.provision "shell",
          path: "scripts/consul.sh",
          env: {
              'CONSUL_VERSION' => CONSUL_VERSION,
              'ENTERPRISE' => ENTERPRISE,
              'CONSUL_ACL' => CONSUL_ACL,
              'CONSUL_TYPE' => 'client'
          }

      v1.vm.provision "shell",
          path: "scripts/vault.sh",
          env: { 'VAULT_VERSION' => VAULT_VERSION }
  end

  config.vm.define "vault2" do |v2|
      v2.vm.hostname = "v2"
      v2.vm.network "private_network", ip: "10.100.1.12"
      v2.vm.provision "shell",
          path: "scripts/consul.sh",
          env: {
              'CONSUL_VERSION' => CONSUL_VERSION,
              'ENTERPRISE' => ENTERPRISE,
              'CONSUL_ACL' => CONSUL_ACL,
              'CONSUL_TYPE' => 'client'
          }

      v2.vm.provision "shell",
          path: "scripts/vault.sh",
          env: { 'VAULT_VERSION' => VAULT_VERSION }
  end
end
