################################################################################
# AWS

provider aws {
  region = var.requestor_region
  alias  = "requestor"
}

provider aws {
  region = var.accepter_region
  alias  = "accepter"
}
