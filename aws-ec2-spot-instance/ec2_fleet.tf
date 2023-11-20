
resource "aws_ec2_fleet" "main" {
  type = "maintain"

  terminate_instances                 = true
  terminate_instances_with_expiration = true
  replace_unhealthy_instances         = true

  target_capacity_specification {
    default_target_capacity_type = "spot"
    total_target_capacity        = 1
  }

  launch_template_config {
    launch_template_specification {
      launch_template_id = aws_launch_template.main.id
      version            = aws_launch_template.main.latest_version
    }
    override {
      #max_price = 1
      instance_requirements {
        vcpu_count {
          max = 2
          min = 1
        }
        memory_mib {
          max = 2048
          min = 1024
        }
        burstable_performance = "included"
      }
    }
  }

  spot_options {
    allocation_strategy = "capacity-optimized"
  }

  tags = {
    Name = var.project
  }
}
