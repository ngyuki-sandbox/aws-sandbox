
resource "aws_launch_template" "main" {
  name     = var.project
  image_id = "ami-093467ec28ae4fe03" # al2023

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name   = "${var.project}-launch-instance"
      Launch = "instance"

    }
  }

  tag_specifications {
    resource_type = "spot-instances-request"
    tags = {
      Name : "${var.project}-launch-spot"
      Launch = "spot"
    }
  }
}
