
provider "aws" {
  default_tags {
    tags = merge(var.default_tags, {
      Path = basename(abspath(path.root))
    })
  }
}
