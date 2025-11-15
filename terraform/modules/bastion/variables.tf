output "instance_id" {
  description = "ID of the bastion instance"
  value       = aws_instance.bastion.id
}

output "public_ip" {
  description = "Public IP address of the bastion instance"
  value       = aws_instance.bastion.public_ip
}

output "public_dns" {
  description = "Public DNS name of the bastion instance"
  value       = aws_instance.bastion.public_dns
}
