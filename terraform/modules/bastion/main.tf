resource "aws_instance" "bastion" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.security_group_id]
  key_name               = var.key_name

  root_block_device {
    volume_size           = 10
    volume_type           = "gp3"
    delete_on_termination = true
    encrypted             = true
  }

  user_data = base64encode(<<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y python3 python3-pip
              echo "Bastion host setup complete" > /var/log/bastion-setup.log
              EOF
  )

  tags = merge(
    var.tags,
    {
      Name = var.instance_name
      Type = "Bastion"
    }
  )
}
