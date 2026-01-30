data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Security group allowing SSH + HTTP (demo-wide; tighten for prod)
resource "aws_security_group" "web_sg" {
  name        = "ci-cd-web-sg"
  description = "Allow SSH and HTTP"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All egress"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_instance" "web" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = var.key_pair_name
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  subnet_id              = data.aws_subnets.default.ids[0] # simple pick; adjust if needed
  associate_public_ip_address = true

  count = var.instance_count

  tags = {
    Name = "ci-cd-web-${count.index + 1}"
    Role = "web"
  }

  # Optional: cloud-init to ensure python for Ansible
  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install -y python3 python3-apt
              EOF
}

locals {
  private_ips = [for i in aws_instance.web : i.private_ip]
  public_ips  = [for i in aws_instance.web : i.public_ip]
}

# Render hosts.ini using templatefile (includes PRIVATE IPs)
data "template_file" "hosts" {
  template = file("${path.module}/templates/hosts.ini.tmpl")
  vars = {
    ansible_user = var.ansible_user
    private_ips  = jsonencode(local.private_ips)
    public_ips   = jsonencode(local.public_ips)
  }
}

# Optionally, write hosts.ini into the repo workspace so Ansible can use it directly
resource "local_file" "inventory" {
  filename = "${path.module}/../inventory/hosts.ini"
  content  = data.template_file.hosts.rendered
}
