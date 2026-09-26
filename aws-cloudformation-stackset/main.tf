
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region = var.region
}

variable "region" {
  type    = string
  default = "ap-northeast-1"
}

data "aws_organizations_organization" "main" {
  lifecycle {
    postcondition {
      condition     = contains(self.aws_service_access_principals, "member.org.stacksets.cloudformation.amazonaws.com")
      error_message = "StackSets trusted access is not enabled. Run: `aws cloudformation activate-organizations-access`"
    }
  }
}

resource "aws_cloudformation_stack_set" "main" {
  name             = "sandbox-cfn-stackset"
  permission_model = "SERVICE_MANAGED"
  call_as          = "SELF"
  template_body    = file("${path.module}/template.yaml")

  auto_deployment {
    enabled                          = true
    retain_stacks_on_account_removal = false
  }

  managed_execution {
    active = true
  }
}

resource "aws_cloudformation_stack_instances" "main" {
  stack_set_name = aws_cloudformation_stack_set.main.name
  call_as        = "SELF"
  regions        = [var.region]
  retain_stacks  = false

  deployment_targets {
    organizational_unit_ids = [data.aws_organizations_organization.main.roots[0].id]
  }
}
