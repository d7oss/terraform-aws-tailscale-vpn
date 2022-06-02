# tailscale-vpn

A Terraform module to manage a Tailscale VPN server - why not a bastion too -
in your VPC.

You'll need a Tailscale account, and an auth key, to make use of the VPN.

The managed server also works as a bastion, fits nicely in use cases like
allowing external access into a database from data extracting tools via SSH.


## Usage example

```hcl
module "vpn" {
  source = "d7oss/tailscale-vpn/aws"
  version = "~> 0.0"
  
  # Some metadata
  env_name = "staging"
  hostname = "vpn.${local.DOMAIN_NAME}"

  # Where to put the VPN server in the network
  vpc_id = module.vpc.vpc_id
  subnet_ids = module.vpc.public_subnets

  # SSH connections
  key_name = "my-ec2-key"  # Optional, if you want to use an EC2 key
  extra_ssh_users = [
    { name = "john", pubkey = "ssh-rsa ... john@john-laptop" },
    { name = "bi-tool", pubkey = "ssh-rsa ..." }
  ]

  # Allow extra CIDR blocks, e.g. some external BI tool IP addresses
  ingress_cidr_blocks = {
    "ssh-from-bi-vendor" = {
      cidr_blocks = [
        "1.2.3.4/32",
        "5.6.7.8/32",
      ]
      protocol = "tcp"
      port = 22
    }
  }

  # Tailscale authentication
  tailscale_auth_key = var.tailscale_auth_key
  tailscale_advertise_routes = [module.vpc.vpc_cidr_block]
}

module "database" {
  ...

  # Allow database connection from peers connected to the VPN
  ingress_security_groups = {
    "psql-from-vpn" = { port = 5432, security_group_id = module.vpn.security_group_id }
  }
}
```
