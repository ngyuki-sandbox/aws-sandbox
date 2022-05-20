################################################################################
# Modules
################################################################################

terraform {
  required_version = ">= 1.1.6"

  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

module "alice" {
  source = "./alice"

  assume_role_arn = var.alice_role_arn

  env = {
    region         = "ap-northeast-1"
    vpc_cidr_block = "10.214.25.0/24"
    tag            = "aws-cross-account-rds-alice"
    private_domain = "alice.example.test"
    forward_domain = "example.test"

    subnets = {
      a = {
        cidr_block        = "10.214.25.0/26"
        availability_zone = "ap-northeast-1a"
      }
      c = {
        cidr_block        = "10.214.25.64/26"
        availability_zone = "ap-northeast-1c"
      }
    }

    allow_ssh_ingress = var.allow_ssh_ingress

    allow_rds_ingress = var.allow_rds_ingress

    rds_instance_type      = "db.t3.medium"
    rds_database           = "test"
    rds_username           = "postgres"
    rds_password           = "postgres"
    rds_retention_period   = 1
    rds_backup_window      = "15:00-16:00"
    rds_maintenance_window = "sat:18:00-sat:20:00"
  }

  peer = {
    owner_id   = module.bob.owner_id
    vpc_id     = module.bob.vpc_id
    cidr_block = module.bob.cidr_block
  }
}

module "bob" {
  source = "./bob"

  assume_role_arn = var.bob_role_arn

  env = {
    region         = "ap-northeast-1"
    vpc_cidr_block = "10.215.25.0/24"
    tag            = "aws-cross-account-rds-bob"
    forward_domain = "example.test"
    peer_domain    = "alice.example.test"

    subnets = {
      a = {
        cidr_block        = "10.215.25.0/26"
        availability_zone = "ap-northeast-1a"
      }
      c = {
        cidr_block        = "10.215.25.64/26"
        availability_zone = "ap-northeast-1c"
      }
    }

    allow_ssh_ingress = var.allow_ssh_ingress
  }

  peer = {
    peering_connection_id = module.alice.peering_connection_id
    cidr_block            = module.alice.cidr_block
    zone_id               = module.alice.zone_id
    resolver_inbound_ips  = module.alice.resolver_inbound_ips
  }
}

output "instance" {
  value = module.bob.instance
}

output "rds" {
  value = module.alice.rds
}
