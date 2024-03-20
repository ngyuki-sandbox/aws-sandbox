
provider "aws" {
  region = var.region
  default_tags {
    tags = merge(var.default_tags, {
      Path = basename(dirname(abspath(path.root)))
    })
  }
}
