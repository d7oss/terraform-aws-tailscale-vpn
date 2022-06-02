# tailscale-vpn

A Terraform module to manage a Tailscale VPN server - why not a bastion too -
in your VPC.

You'll need a Tailscale account, and an auth key, to make use of the VPN.

The managed server also works as a bastion, fits nicely in use cases like
allowing external access into a database from data extracting tools via SSH.

DON'T FORGET TO READ [IMPORTANT NOTES](#important-notes) BELOW.


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


## Important notes

- The Tailscale authentication key has to be REUSABLE and EPHEMERAL. This is
  because the VPN server may need to be replaced since we always use the latest
  Amazon Linux 2 AMI.
- The Tailscale authentication key has a maximum expiry of 180 days. Take note
  of your key's expiry somewhere. Once your VPN stops working, this will likely
  be the reason. This can certainly be improved with the right time and effort.
- Once the server authenticates to Tailscale, you'll need to enable its subnet
  routes in order to allow traffic from external nodes into resources in your
  private subnet. This can be done in the _Machines_ page in Tailscale.
