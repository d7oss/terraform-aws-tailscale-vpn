variable "env_name" {
  description = "The environment name to help naming resources."
  type = string
}

variable "extra_security_groups" {
  description = <<-EOT
    A list of extra security groups to associate the server with.
    This module already manages a server-specific security group.
  EOT
  type = list(string)
  default = []
}

variable "ingress_cidr_blocks" {
  description = "Optional ingress rules for CIDR blocks."
  type = map(object({
    cidr_blocks = list(string)
    protocol = string
    port = number
  }))
  default = {}
}

variable "ingress_security_groups" {
  description = "Optional ingress rules for other security groups."
  type = map(object({
    security_group_id = string
    protocol = string
    port = number
  }))
  default = {}
}

variable "key_name" {
  description = <<-EOT
    Optional EC2 key name to SSH with.
    Other keys can be added in `extra_ssh_users`.
  EOT
  type = string
  default = null
}

variable "subnet_ids" {
  description = <<-EOT
    Subnet IDs to place the server in.
    A random one will be picked.
  EOT
  type = list(string)
}

variable "vpc_id" {
  description = "The VPC to place the server in."
  type = string
}

variable "tailscale_auth_key" {
  description = <<-EOT
    The Tailscale authentication key to log the server into the tailnet.
    Make sure it's REUSABLE and EPHEMERAL, and pay attention to its expiry.
    Get one in https://login.tailscale.com/admin/settings/keys
  EOT
  type = string
  sensitive = true
}

variable "tailscale_advertise_routes" {
  description = <<-EOT
    The CIDR blocks to route traffic to.
    E.g. your VPC or private subnets CIDR blocks.
  EOT
  type = list(string)
}

variable "hostname" {
  description = <<-EOT
    A hostname to set in the server.
    Likely matching a domain name to add later.
  EOT
  type = string
}

variable "extra_ssh_users" {
  description = "A collection of extra SSH users to add in the server."
  type = list(object({
    name = string
    pubkey = string
  }))
  default = []
}
