
resource "aws_sfn_state_machine" "start_ecs" {
  name     = "${var.name}-start-ecs"
  role_arn = aws_iam_role.sfn.arn
  definition = jsonencode({
    StartAt : "Context",
    States : {
      Context : {
        Type : "Pass",
        Result : {
          ecs_cluster_name : var.ecs_cluster_name,
          ecs_services : var.ecs_services,
        },
        ResultPath : "$",
        Next : "ECS"
      },
      ECS : {
        Type : "Map",
        ItemsPath : "$.ecs_services",
        MaxConcurrency : 10,
        Parameters : {
          "cluster.$" : "$.ecs_cluster_name",
          "service.$" : "$$.Map.Item.Value",
        },
        Iterator : {
          StartAt : "StartService",
          States : {
            StartService : {
              Type : "Task",
              Resource : "arn:aws:states:::aws-sdk:ecs:updateService",
              Parameters : {
                "Cluster.$" : "$.cluster",
                "Service.$" : "$.service",
                "DesiredCount" : 1
              },
              End : true
            }
          }
        },
        End : true
      },
    }
  })
}

resource "aws_sfn_state_machine" "start_rds" {
  name     = "${var.name}-start-rds"
  role_arn = aws_iam_role.sfn.arn
  definition = jsonencode({
    StartAt : "StartDBCluster",
    States : {
      StartDBCluster : {
        Type : "Task",
        Resource : "arn:aws:states:::aws-sdk:rds:startDBCluster",
        Parameters : {
          "DbClusterIdentifier" : var.aurora_cluster_id
        },
        End : true
      }
    }
  })
}
