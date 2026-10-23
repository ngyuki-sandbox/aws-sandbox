
provider "aws" {
  alias  = "tokyo"
  region = "ap-northeast-1"
  default_tags {
    tags = merge(var.default_tags, {
      Path = basename(abspath(path.root))
    })
  }
}

provider "aws" {
  alias  = "osaka"
  region = "ap-northeast-3"
  default_tags {
    tags = merge(var.default_tags, {
      Path = basename(abspath(path.root))
    })
  }
}
