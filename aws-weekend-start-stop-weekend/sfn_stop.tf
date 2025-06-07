
resource "aws_sfn_state_machine" "stop_ecs" {
  name     = "${var.name}-stop-ecs"
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
          StartAt : "StopService",
          States : {
            StopService : {
              Type : "Task",
              Resource : "arn:aws:states:::aws-sdk:ecs:updateService",
              Parameters : {
                "Cluster.$" : "$.cluster",
                "Service.$" : "$.service",
                "DesiredCount" : 0
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

resource "aws_sfn_state_machine" "stop_rds" {
  name     = "${var.name}-stop-rds"
  role_arn = aws_iam_role.sfn.arn
  definition = jsonencode({
    StartAt : "StopDBCluster",
    States : {
      StopDBCluster : {
        Type : "Task",
        Resource : "arn:aws:states:::aws-sdk:rds:stopDBCluster",
        Parameters : {
          "DbClusterIdentifier" : var.aurora_cluster_id
        },
        End : true
      }
    }
  })
}
