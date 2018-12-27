////////////////////////////////////////////////////////////////////////////////
// AWS

provider "aws" {
  region = "ap-northeast-1"
}

////////////////////////////////////////////////////////////////////////////////
// Variable

variable "ec2_key_name" {}

variable "eks_node_ami" {}

variable "bastion_ami" {}

variable "my_cidr_blocks" {
  type = "list"
}

////////////////////////////////////////////////////////////////////////////////
// IAM

resource "aws_iam_role" "cluster" {
  name = "hello-eks-cluster"

  assume_role_policy = <<EOS
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOS
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
  role       = "${aws_iam_role.cluster.name}"
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSServicePolicy" {
  role       = "${aws_iam_role.cluster.name}"
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
}

resource "aws_iam_instance_profile" "node" {
  name = "hello-eks-node"
  role = "${aws_iam_role.node.name}"
}

resource "aws_iam_role" "node" {
  name = "hello-eks-node"

  assume_role_policy = <<EOS
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOS
}

resource "aws_iam_role_policy_attachment" "profile_AmazonEKSWorkerNodePolicy" {
  role       = "${aws_iam_role.node.name}"
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "profile_AmazonEKS_CNI_Policy" {
  role       = "${aws_iam_role.node.name}"
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "profile_AmazonEC2ContainerRegistryReadOnly" {
  role       = "${aws_iam_role.node.name}"
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

////////////////////////////////////////////////////////////////////////////////
// VPC

locals {
  availability_zones = [
    "ap-northeast-1a",
    "ap-northeast-1c",
    "ap-northeast-1d",
  ]
}

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name                              = "hello-eks"
    "kubernetes.io/cluster/hello-eks" = "shared"
  }
}

resource "aws_subnet" "public" {
  count             = "${length(local.availability_zones)}"
  vpc_id            = "${aws_vpc.main.id}"
  cidr_block        = "${cidrsubnet(aws_vpc.main.cidr_block, 8, count.index)}"
  availability_zone = "${local.availability_zones[count.index]}"

  tags = {
    Name                              = "hello-eks-public"
    "kubernetes.io/cluster/hello-eks" = "shared"
  }
}

resource "aws_subnet" "private" {
  count             = "${length(local.availability_zones)}"
  vpc_id            = "${aws_vpc.main.id}"
  cidr_block        = "${cidrsubnet(aws_vpc.main.cidr_block, 8, count.index + length(local.availability_zones))}"
  availability_zone = "${local.availability_zones[count.index]}"

  tags = {
    Name                              = "hello-eks-private"
    "kubernetes.io/cluster/hello-eks" = "shared"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = "${aws_vpc.main.id}"

  tags = {
    Name = "hello-eks"
  }
}

resource "aws_eip" "nat" {
  count = "${length(local.availability_zones)}"
  vpc   = true

  tags = {
    Name = "hello-eks"
  }
}

resource "aws_nat_gateway" "ngw" {
  count         = "${length(local.availability_zones)}"
  subnet_id     = "${element(aws_subnet.public.*.id, count.index)}"
  allocation_id = "${element(aws_eip.nat.*.id, count.index)}"

  tags = {
    Name = "hello-eks"
  }
}

resource "aws_route" "main" {
  route_table_id         = "${aws_vpc.main.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.igw.id}"
}

resource "aws_route_table" "private" {
  count  = "${length(local.availability_zones)}"
  vpc_id = "${aws_vpc.main.id}"

  tags = {
    Name = "hello-eks-private"
  }
}

resource "aws_route" "private" {
  count                  = "${length(local.availability_zones)}"
  route_table_id         = "${element(aws_route_table.private.*.id, count.index)}"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = "${element(aws_nat_gateway.ngw.*.id, count.index)}"
}

resource "aws_route_table_association" "private" {
  count          = "${length(local.availability_zones)}"
  subnet_id      = "${element(aws_subnet.private.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.private.*.id, count.index)}"
}

resource "aws_security_group" "control" {
  name        = "hello-eks-control"
  description = "hello-eks-control"
  vpc_id      = "${aws_vpc.main.id}"
}

resource "aws_security_group_rule" "control_from_node" {
  security_group_id        = "${aws_security_group.control.id}"
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = "${aws_security_group.node.id}"
}

resource "aws_security_group_rule" "control_to_node_443" {
 security_group_id        = "${aws_security_group.control.id}"
 type                     = "egress"
 from_port                = 443
 to_port                  = 443
 protocol                 = "tcp"
 source_security_group_id = "${aws_security_group.node.id}"
}

resource "aws_security_group_rule" "control_to_node_1025" {
  security_group_id        = "${aws_security_group.control.id}"
  type                     = "egress"
  from_port                = 1025
  to_port                  = 65535
  protocol                 = "tcp"
  source_security_group_id = "${aws_security_group.node.id}"
}

resource "aws_security_group" "node" {
  name        = "hello-eks-node"
  description = "hello-eks-node"
  vpc_id      = "${aws_vpc.main.id}"

  tags = {
    "kubernetes.io/cluster/hello-eks" = "owned"
  }

  egress = {
    from_port         = 0
    to_port           = 0
    protocol          = -1
    cidr_blocks       = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "node_self" {
  security_group_id = "${aws_security_group.node.id}"
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = -1
  self              = true
}

resource "aws_security_group_rule" "node_from_control_443" {
  security_group_id        = "${aws_security_group.node.id}"
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = "${aws_security_group.control.id}"
}

resource "aws_security_group_rule" "node_from_control_1025" {
  security_group_id        = "${aws_security_group.node.id}"
  type                     = "ingress"
  from_port                = 1025
  to_port                  = 65535
  protocol                 = "tcp"
  source_security_group_id = "${aws_security_group.control.id}"
}

resource "aws_security_group_rule" "node_from_bastion" {
  security_group_id        = "${aws_security_group.node.id}"
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = "${aws_security_group.bastion.id}"
}

resource "aws_security_group" "bastion" {
  name        = "hello-eks-bastion"
  description = "hello-eks-bastion"
  vpc_id      = "${aws_vpc.main.id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.my_cidr_blocks}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}

////////////////////////////////////////////////////////////////////////////////
// EKS

resource "aws_eks_cluster" "cluster" {
  name     = "hello-eks"
  role_arn = "${aws_iam_role.cluster.arn}"

  vpc_config {
    subnet_ids         = ["${aws_subnet.public.*.id}", "${aws_subnet.private.*.id}"]
    security_group_ids = ["${aws_security_group.control.id}"]
  }
}

////////////////////////////////////////////////////////////////////////////////
// AutoScaling

resource "aws_launch_configuration" "node" {
  name_prefix          = "hello-eks-"
  image_id             = "${var.eks_node_ami}"
  instance_type        = "t2.nano"
  key_name             = "${var.ec2_key_name}"
  iam_instance_profile = "${aws_iam_instance_profile.node.id}"
  security_groups      = ["${aws_security_group.node.id}"]

  root_block_device = {
    volume_type = "gp2"
    volume_size = 20
  }

  user_data = <<EOS
#!/bin/bash
set -o xtrace
/etc/eks/bootstrap.sh ${aws_eks_cluster.cluster.name}
EOS

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "node" {
  name                 = "hello-eks-group"
  desired_capacity     = 3
  max_size             = 3
  min_size             = 1
  launch_configuration = "${aws_launch_configuration.node.name}"
  vpc_zone_identifier  = ["${aws_subnet.private.*.id}"]

  tag {
    key                 = "Name"
    value               = "hello-eks-node"
    propagate_at_launch = true
  }

  tag {
    key                 = "kubernetes.io/cluster/hello-eks"
    value               = "owned"
    propagate_at_launch = true
  }

  timeouts {
    delete = "15m"
  }

  lifecycle {
    create_before_destroy = true
  }
}

////////////////////////////////////////////////////////////////////////////////
// EC2

resource "aws_instance" "bastion" {
  availability_zone           = "${local.availability_zones[0]}"
  ami                         = "${var.bastion_ami}"
  instance_type               = "t3.nano"
  key_name                    = "${var.ec2_key_name}"
  monitoring                  = false
  vpc_security_group_ids      = ["${aws_security_group.bastion.id}"]
  subnet_id                   = "${aws_subnet.public.*.id[0]}"
  associate_public_ip_address = true

  tags {
    Name = "bastion"
  }

  root_block_device {
    volume_size = 8
    volume_type = "gp2"
  }
}

////////////////////////////////////////////////////////////////////////////////
// Output

output "aws_iam_role.node.arn" {
  value = "${aws_iam_role.node.arn}"
}

output "aws_instance.bastion.public_ip" {
  value = "${aws_instance.bastion.public_ip}"
}
