variable "instance_name" {
  description = "Name tag for the bastion instance"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "ami_id" {
  description = "AMI ID for the bastion instance"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID where the bastion will be launched"
  type        = string
}

variable "security_group_id" {
  description = "Security group ID to attach to the bastion"
  type        = string
}

variable "key_name" {
  description = "SSH key pair name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "tags" {
  description = "Additional tags for the bastion"
  type        = map(string)
  default     = {}
}
