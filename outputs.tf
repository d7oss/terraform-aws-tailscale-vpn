output "ip_address" {
  description = "The Elastic IP address associated with the server."
  value = aws_eip.main.public_ip
}

output "security_group_id" {
  description = "The ID of the Security Group for the server."
  value = module.security_group.id
}

output "hostname" {
  description = "The hostname of the server (same as input)."
  value = var.hostname
}

output "security_group_rules" {
  description = "Common security group rules that can be merged into other resources."
  value = {
    for label, port in {
      "http" = 80
      "https" = 443
      "ssh" = 22
    }: label => {
      "${label}-from-${var.env_name}-vpn" = {
        security_group_id = module.security_group.id
        protocol = "tcp", port = port
      }
    }
  }
}
