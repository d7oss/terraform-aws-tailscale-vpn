locals {
  common_name = "${var.env_name}-vpn"

  user_data = templatefile("${path.module}/user-data.yml.tpl", {
    tailscale_auth_key = var.tailscale_auth_key
    tailscale_advertise_routes = join(",", var.tailscale_advertise_routes)
    hostname = var.hostname
    ssh_users = var.extra_ssh_users
  })
}

data "aws_ami" "main" {
  /*
  Download latest AMI info for Amazon Linux 2
  */
  most_recent = true  # This will keep the server up to date. RECOMMENDED.
  owners = ["amazon"]

  filter {
    name = "name"
    values = ["amzn2-ami-*-x86_64-gp2"]
  }

  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }
}

resource "random_shuffle" "subnet" {
  /*
  Pick a random subnet ID from the list
  */
  input = var.subnet_ids
  result_count = 1
}

resource "aws_eip" "main" {
  /*
  A fixed IP address
  */
  vpc = true
  tags = { "Name" = local.common_name }
}

resource "aws_instance" "main" {
  /*
  The VPN-bastion server
  */
  ami = data.aws_ami.main.id
  instance_type = "t3.micro"  # Usually more than enough
  key_name = var.key_name
  subnet_id = random_shuffle.subnet.result[0]
  vpc_security_group_ids = concat([
    module.security_group.id,
  ], var.extra_security_groups)
  user_data = local.user_data
  tags = { "Name" = local.common_name }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_eip_association" "main" {
  /*
  Associate the server to the IP address
  */
  instance_id = aws_instance.main.id
  allocation_id = aws_eip.main.id
}

module "security_group" {
  /*
  The security group specific for the server
  */
  source = "emyller/security-group/aws"
  version = "~> 1.0"
  name = "i-${local.common_name}"
  vpc_id = var.vpc_id
  ingress_cidr_blocks = var.ingress_cidr_blocks
  ingress_security_groups = var.ingress_security_groups
}

resource "aws_route53_record" "main" {
  /*
  DNS record pointing to the VPN server
  */
  count = var.dns_zone_id == null ? 0 : 1

  zone_id = var.dns_zone_id
  name = var.hostname
  type = "A"
  ttl = 300
  records = [aws_eip.main.public_ip]
}
