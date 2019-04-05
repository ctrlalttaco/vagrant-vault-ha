# Consul ACL for Vault

## Consul HCL Configuration

The ACL block must be configured on every Consul server and client

```
acl {
    # Enable the ACL system
    enabled = true

    # Always deny by default
    default_policy = "deny"

    # Allow cached objects to be accessible when the leader is down
    down_policy = "extend-cache"
}
```

## Consul ACL Bootstrap

Create the Bootstrap Token

```
$ consul acl bootstrap
AccessorID:   5f86e12b-4a99-9225-ed3b-c21cf71af387
SecretID:     ba551ccc-fa57-2d1c-edc7-ed1734405542
Description:  Bootstrap Token (Global Management)
Local:        false
Create Time:  2019-03-22 01:42:05.498406028 +0000 UTC
Policies:
   00000000-0000-0000-0000-000000000001 - global-management

```

Note the SecretID. This will become your master token.

## Consul Server Nodes

Add the master token to the Consul server cluster ACL configuration

```
acl {
    ...
    tokens {
        master = "ba551ccc-fa57-2d1c-edc7-ed1734405542"
    }
}
```

Restart the Consul server service and repeat for each Consul server

## Vault Server Nodes

Create an HCL file containing the ACL policy that will be used by Vault

```
node_prefix "" {
    policy = "write"
}

service_prefix "" {
    policy = "read"
}
```

Create the Consul client agent policy

```
$ consul acl policy create -name "vault-agent-policy" \
-rules @agent.hcl \
--token="ba551ccc-fa57-2d1c-edc7-ed1734405542"

ID:           cb16d424-f4a5-c202-c6ac-a619e495e098
Name:         vault-agent-policy
Description:  
Datacenters:  
Rules:
node_prefix "" {
    policy = "write"
}

service_prefix "" {
    policy = "read"
}
```

Create the Consul client agent token

```
$ consul acl token create -description "Vault agent policy" \
-policy-name "vault-agent-policy" \
--token="ba551ccc-fa57-2d1c-edc7-ed1734405542"

AccessorID:   67d7246c-e23f-c3ba-d005-b8f0ac4b3b6c
SecretID:     ada782d5-a150-b2bb-d450-57e08cb91851
Description:  Vault agent policy
Local:        false
Create Time:  2019-03-22 02:16:29.523936945 +0000 UTC
Policies:
   cb16d424-f4a5-c202-c6ac-a619e495e098 - vault-agent-policy
```

Note the SecretID. This will be used in the Consul client HCL configuration.

Add the agent token to the Consul client ACL configuration

```
acl {
    ...
    tokens {
        agent = "ada782d5-a150-b2bb-d450-57e08cb91851"
    }
}
```

Restart the Consul client service

Create an HCL file containing the ACL policy that will be used by Vault

```
node_prefix "" {
    policy = "write"
}

service "vault" {
    policy = "write"
}

agent_prefix "" {
    policy = "write"
}

key_prefix "vault/" {
    policy = "write"
}

session_prefix "" {
    policy = "write"
}
```

Create the Vault client token

```
$ consul acl policy create -name "vault-client-policy" \
-rules @client.hcl \
--token="ba551ccc-fa57-2d1c-edc7-ed1734405542"

ID:           71435aed-5432-3f25-c5d3-5b26621531c6
Name:         vault-policy
Description:  
Datacenters:  
Rules:
node_prefix "" {
    policy = "write"
}

service "vault" {
    policy = "write"
}

agent_prefix "" {
    policy = "write"
}

key_prefix "vault/" {
    policy = "write"
}

session_prefix "" {
    policy = "write"
}
```

Create a client token using the created policy

```
$ consul acl token create -description="Vault client token" \
-policy-name="vault-client-policy" \
--token="ba551ccc-fa57-2d1c-edc7-ed1734405542"

AccessorID:   5391a750-933f-bc31-1a71-610476d9f9f3
SecretID:     2f48b885-554d-f414-5857-0771c31935ec
Description:  Vault client token
Local:        false
Create Time:  2019-03-22 02:07:35.518082307 +0000 UTC
Policies:
   71435aed-5432-3f25-c5d3-5b26621531c6 - vault-policy
```

Note the SecretID. This will be used in the Vault HCL configuration.

Modify the Vault HCL configuration to include the Consul ACL token

```
storage "consul" {
    token = "2f48b885-554d-f414-5857-0771c31935ec"
}
```

Restart the Vault service

Repeat for each Vault node