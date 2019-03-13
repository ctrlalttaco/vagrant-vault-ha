## Synopsis

These certificates are generated using Cloudflare's PKI and TLS toolkit

## Installation

### MacOS

`brew install cfssl`

### Linux 64-bit

```
mkdir ~/bin
curl -s -L -o ~/bin/cfssl https://pkg.cfssl.org/R1.2/cfssl_linux-amd64
curl -s -L -o ~/bin/cfssljson https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64
chmod +x ~/bin/{cfssl,cfssljson}
export PATH=$PATH:~/bin
```
## Usage

### Generate CA

`cfssl gencert -initca ca-csr.json | cfssljson -bare ca -`

### Generate signed server certificate

`cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=server consul-server.json | cfssljson -bare server`

### Generate signed client certificate

`cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=client consul-client.json | cfssljson -bare client`

### Generate signed CLI certificate

`cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=client consul-cli.json | cfssljson -bare cli`