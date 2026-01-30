variable "aws_region" {
  type        = string
  description = "AWS region"
  default     = "ap-south-1"
}

variable "key_pair_name" {
  type        = string
  description = "Existing AWS key pair name attached to EC2 instances"
}

variable "instance_count" {
  type        = number
  default     = 2
}

variable "instance_type" {
  type        = string
  default     = "t3.micro"
}

variable "ansible_user" {
  type        = string
  description = "SSH user Ansible should use (Ubuntu images use 'ubuntu')"
  default     = "ubuntu"
}
