////////////////////////////////////////////////////////////////////////////////
// AWS

provider "aws" {
  region = "ap-northeast-1"
}

////////////////////////////////////////////////////////////////////////////////
// Variable

variable "key_name" {}

////////////////////////////////////////////////////////////////////////////////
// IAM

resource "aws_iam_role" "ec2" {
  name = "hello-cwagent"

  assume_role_policy = <<EOS
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOS
}

resource "aws_iam_role_policy_attachment" "ec2_CloudWatchAgentServerPolicy" {
  role       = "${aws_iam_role.ec2.name}"
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "ec2" {
  name = "hello-cwagent"
  role = "${aws_iam_role.ec2.name}"
}

////////////////////////////////////////////////////////////////////////////////
// VPC

data "aws_vpc" "default" {
  default = true
}

data "aws_subnet_ids" "default" {
  vpc_id = "${data.aws_vpc.default.id}"
}

data "aws_security_group" "default" {
  name = "default"
}

////////////////////////////////////////////////////////////////////////////////
// SSM

resource "aws_ssm_parameter" "cwagent" {
  name  = "AmazonCloudWatch-AgentConfig"
  type  = "String"
  value = "${file("amazon-cloudwatch-agent.json")}"
}

////////////////////////////////////////////////////////////////////////////////
// EC2

data "aws_ami" "app" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

resource "aws_instance" "app" {
  count                       = 2
  ami                         = "${data.aws_ami.app.id}"
  instance_type               = "t2.nano"
  key_name                    = "${var.key_name}"
  iam_instance_profile        = "${aws_iam_instance_profile.ec2.name}"
  subnet_id                   = "${data.aws_subnet_ids.default.ids[count.index]}"
  vpc_security_group_ids      = ["${data.aws_security_group.default.id}"]
  associate_public_ip_address = true

  user_data = "${file("user_data.yaml")}"

  tags {
    Name = "hello-cwagent"
  }

  root_block_device {
    volume_size           = 8
    volume_type           = "gp2"
    delete_on_termination = true
  }

  depends_on = ["aws_ssm_parameter.cwagent"]
}

output "aws_instance.app.public_ip" {
  value = "${aws_instance.app.*.public_ip}"
}
