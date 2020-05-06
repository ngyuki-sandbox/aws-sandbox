################################################################################
# variable

variable tag {}
variable region {}
variable key_name {}

variable vpc_cidr_block {}

variable transit_gateway_has { default = false }
variable transit_gateway_id { default = "" }
variable transit_gateway_routes { default = [] }
