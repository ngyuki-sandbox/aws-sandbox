################################################################################
# EC2
################################################################################

resource "aws_instance" "this" {
  ami                    = var.ami_id
  instance_type          = "t3.nano"
  vpc_security_group_ids = var.vpc_security_group_ids
  subnet_id              = var.subnet_id

  user_data                   = <<-EOS
    #cloud-config
    timezone: "Asia/Tokyo"
    ssh_authorized_keys: ${jsonencode(var.authorized_keys)}
  EOS

  tags = {
    Name = local.name
  }

  root_block_device {
    volume_type = "gp2"
    volume_size = "8"
    tags = {
      Name = local.name
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_target_group_attachment" "this" {
  target_group_arn = var.target_group_arn
  target_id        = aws_instance.this.id

  lifecycle {
    create_before_destroy = true
  }

  provisioner "local-exec" {
    command = <<-EOF
      set -ex -o pipefail
      if [ "$wait" -ne 0 ]; then
        timeout "$wait" aws elbv2 wait target-in-service \
          --target-group-arn "$target_group_arn" \
          --targets "Id=$target_id"
      fi
    EOF
    environment = {
      wait = var.wait
      target_group_arn = self.target_group_arn
      target_id = self.target_id
    }
  }
}
