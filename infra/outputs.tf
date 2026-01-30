output "web_private_ips" {
  description = "Private IPs of web instances"
  value       = [for i in aws_instance.web : i.private_ip]
}

output "web_public_ips" {
  description = "Public IPs of web instances"
  value       = [for i in aws_instance.web : i.public_ip]
}

# Also output rendered hosts.ini so Jenkins can write it if needed
output "ansible_hosts_ini" {
  description = "Rendered Ansible inventory"
  value       = data.template_file.hosts.rendered
}
