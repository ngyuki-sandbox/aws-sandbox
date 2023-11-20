
resource "aws_autoscaling_group" "main" {
  name = var.project

  force_delete              = true
  force_delete_warm_pool    = true
  capacity_rebalance        = true
  wait_for_capacity_timeout = 0
  default_cooldown          = 10

  min_size = 1
  max_size = 1

  mixed_instances_policy {
    instances_distribution {
      on_demand_percentage_above_base_capacity = 0
      spot_allocation_strategy                 = "price-capacity-optimized"
    }
    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.main.id
        version            = aws_launch_template.main.latest_version
      }
      override {
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
  }

  vpc_zone_identifier = data.aws_subnets.main.ids

  tag {
    key                 = "Name"
    value               = "${var.project}-auto"
    propagate_at_launch = true
  }

  lifecycle {
    ignore_changes = [
      min_size,
      max_size,
      desired_capacity,
    ]
  }
}

resource "aws_autoscaling_schedule" "main" {
  autoscaling_group_name = aws_autoscaling_group.main.name
  scheduled_action_name  = var.project

  min_size         = 0
  max_size         = 0
  desired_capacity = 0
  recurrence       = "*/5 * * * *"
  time_zone        = "Asia/Tokyo"
}
