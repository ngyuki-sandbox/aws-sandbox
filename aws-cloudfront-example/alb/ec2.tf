
data "aws_ssm_parameter" "ami_amazon_linux" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

locals {
  ec2_user_data = <<-EOS
    #cloud-config
    timezone: "Asia/Tokyo"
    hostname: "${var.name}-server"
    ssh_authorized_keys: ${jsonencode(var.authorized_keys)}
    runcmd:
      - dnf install -y nginx
      - dnf install -y php8.2-fpm php8.2-cli
      - systemctl enable --now nginx
      - systemctl enable --now php-fpm

    write_files:
      - path: /etc/nginx/default.d/app.conf
        content: ${jsonencode(file("${path.module}/files/app.conf"))}

      - path: /var/www/html/index.php
        content: ${jsonencode(file("${path.module}/files/index.php"))}

      - path: /var/www/html/style.css
        content: ${jsonencode(file("${path.module}/files/style.css"))}

      - path: /var/www/html/script.js
        content: ${jsonencode(file("${path.module}/files/script.js"))}
  EOS
}

resource "aws_instance" "main" {
  ami                         = data.aws_ssm_parameter.ami_amazon_linux.value
  instance_type               = "t3.nano"
  subnet_id                   = data.aws_subnets.main.ids[0]
  vpc_security_group_ids      = [aws_security_group.main.id]
  iam_instance_profile        = aws_iam_instance_profile.main.name
  ebs_optimized               = false
  monitoring                  = false
  associate_public_ip_address = true

  user_data                   = local.ec2_user_data
  user_data_replace_on_change = false

  root_block_device {
    volume_type = "gp2"
    volume_size = 8
  }

  tags = {
    Name = var.name
  }

  lifecycle {
    ignore_changes = [user_data]
  }
}

resource "aws_lb_target_group_attachment" "main" {
  target_group_arn = aws_lb_target_group.main.arn
  target_id        = aws_instance.main.id
}

resource "aws_iam_role" "main" {
  name = "${var.name}-ec2"

  assume_role_policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Action : "sts:AssumeRole",
        Effect : "Allow",
        Principal : {
          Service : "ec2.amazonaws.com",
        }
      }
    ]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
  ]
}

resource "aws_iam_instance_profile" "main" {
  name = aws_iam_role.main.name
  role = aws_iam_role.main.name
}
