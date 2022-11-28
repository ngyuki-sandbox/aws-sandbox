
data "aws_vpc" "vpc" {
  default = true
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_subnet" "subnets" {
  for_each = { for x in data.aws_availability_zones.available.names : x => x }

  vpc_id            = data.aws_vpc.vpc.id
  availability_zone = each.value
}
