output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = aws_subnet.public.id
}

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.web.id
}

output "ec2_instance_id" {
  description = "ID of the EC2 instance"
  value       = module.ec2.instance_id
}

output "ec2_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = module.ec2.public_ip
}

output "ec2_public_dns" {
  description = "Public DNS name of the EC2 instance"
  value       = module.ec2.public_dns
}

output "ssh_connection_command" {
  description = "SSH command to connect to the EC2 instance"
  value       = "ssh -i ~/.ssh/id_rsa ubuntu@${module.ec2.public_ip}"
}

output "bastion_public_ip" {
  description = "Public IP address of the bastion host"
  value       = var.enable_bastion ? module.bastion[0].public_ip : null
}

output "website_url" {
  description = "URL to access the website"
  value       = "http://${module.ec2.public_ip}"
}

output "cloudwatch_log_groups" {
  description = "CloudWatch log group names"
  value = var.enable_monitoring ? {
    syslog       = aws_cloudwatch_log_group.syslog[0].name
    nginx_access = aws_cloudwatch_log_group.nginx_access[0].name
    nginx_error  = aws_cloudwatch_log_group.nginx_error[0].name
  } : null
}
