# Vagrant Consul and Vault

## Synopsis

Build a three-node Consul and two-node Vault cluster using HashiCorp Vagrant.

## Configuration

### Consul

Version : `1.4.4`

TLS Enabled : `true`

Datacenter Name : `vagrant`

Operating System : `CentOS 7`

### Vault

Version : `1.1.0`

TLS Enabled : `true`

Operating System : `CentOS 7`

### Nodes

consul0 - `172.20.0.11`

consul1 - `172.20.0.12`

consul2 - `172.20.0.13`

vault1 - `172.20.10.11`

vault2 - `172.20.10.12`

## Usage

``` bash
vagrant up
```

## Environment Variables

`CONSUL_VERSION` - Specify the version of Consul to use

`CONSUL_ENTERPRISE` - Download Consul Enterprise binary

`CONSUL_ACL` - Set to `true` to enable ACL on Consul

`VAULT_VERSION` - Specify the version of Vault to use

## Consul ACL Policies

Follow the [Consul ACL Guide](https://learn.hashicorp.com/consul/advanced/day-1-operations/acl-guide) to bootstrap and configure the agent token.

Example Consul Agent Policy:

```
node_prefix "consul" {
    policy = "write"
}

service_prefix "" {
    policy = "read"
}
```

Example Vault Consul Client Policy:

```
node_prefix "vault" {
    policy = "write"
}

service "vault" {
    policy = "write"
}

agent_prefix "vault" {
    policy = "write"
}

key_prefix "vault/" {
    policy = "write"
}

session_prefix "" {
    policy = "write"
}
```

## References

[Consul Documentation](https://www.consul.io/docs/index.html)

[Consul Guides](https://www.consul.io/docs/guides/index.html)

[Consul API Reference](https://www.consul.io/api/index.html)

[HashiCorp Learn - Consul](https://learn.hashicorp.com/consul)
