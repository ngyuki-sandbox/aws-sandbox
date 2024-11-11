
data "aws_vpc" "main" {
  default = true
}

data "aws_availability_zones" "main" {
  state = "available"
}

data "aws_subnet" "main" {
  for_each = { for x in data.aws_availability_zones.main.names : x => x }

  vpc_id            = data.aws_vpc.main.id
  availability_zone = each.value
}
