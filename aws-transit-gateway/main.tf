variable key_name {}

module tgw {
  source = "./tgw"
  tag    = "tgw"

  requestor_region = "us-west-2"
  requestor_cidrs  = ["10.100.0.0/16"]

  accepter_region = "ap-northeast-1"
  accepter_cidrs  = ["10.101.0.0/16", "10.102.0.0/16"]
}

module oregon_vpc {
  source         = "./vpc"
  tag            = "tgw-oregon-vpc"
  region         = "us-west-2"
  vpc_cidr_block = "10.100.0.0/16"
  key_name       = var.key_name

  transit_gateway_has    = true
  transit_gateway_id     = module.tgw.requestor_transit_gateway_id
  transit_gateway_routes = ["10.101.0.0/16", "10.102.0.0/16"]
}

module tokyo_vpc_1 {
  source         = "./vpc"
  tag            = "tgw-tokyo-vpc-1"
  region         = "ap-northeast-1"
  vpc_cidr_block = "10.101.0.0/16"
  key_name       = var.key_name

  transit_gateway_has    = true
  transit_gateway_id     = module.tgw.accepter_transit_gateway_id
  transit_gateway_routes = ["10.100.0.0/16", "10.102.0.0/16"]
}

module tokyo_vpc_2 {
  source         = "./vpc"
  tag            = "tgw-tokyo-vpc-2"
  region         = "ap-northeast-1"
  vpc_cidr_block = "10.102.0.0/16"
  key_name       = var.key_name

  transit_gateway_has    = true
  transit_gateway_id     = module.tgw.accepter_transit_gateway_id
  transit_gateway_routes = ["10.100.0.0/16", "10.101.0.0/16"]
}

output instances {
  value = {
    oregon = module.oregon_vpc.instances
    vpc_1  = module.tokyo_vpc_1.instances
    vpc_2  = module.tokyo_vpc_2.instances
  }
}
