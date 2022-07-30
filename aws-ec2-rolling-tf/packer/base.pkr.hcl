packer {
  required_plugins {
    amazon = {
      version = ">= 0.0.2"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

locals {
  name      = "base"
  timestamp = "{{ strftime \"%Y%m%dT%H%M%S\" }}"
}

source "amazon-ebs" "base" {
  ami_name = "${local.name}-${local.timestamp}"
  tags = {
    Name      = local.name,
    timestamp = local.timestamp,
  }
  instance_type = "t2.medium"

  user_data = <<-EOS
    #cloud-config
    timezone: "Asia/Tokyo"
  EOS

  launch_block_device_mappings {
    device_name           = "/dev/sda1"
    volume_size           = 8
    delete_on_termination = true
  }

  // source_ami = "ami-06ce6680729711877"
  source_ami_filter {
    owners = ["131827586825"]
    filters = {
      name                = "OL8.*"
      description         = "Oracle Linux 8 *"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
      architecture        = "x86_64"
      state               = "available"
    }
    most_recent = true
  }

  ssh_username = "ec2-user"
  ssh_timeout  = "1m"
}

build {
  name = "base"
  sources = [
    "source.amazon-ebs.base"
  ]
  provisioner "shell" {
    environment_vars = [
      "LANG=C",
    ]
    scripts = ["setup.sh"]
  }
}
