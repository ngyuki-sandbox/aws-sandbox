
variable "region" {}
variable "domain" {}
variable "zone_id" {}

provider "aws" {
  region = var.region
}

resource "aws_ses_domain_identity" "this" {
  domain = var.domain
}

# 複数リージョンが同じレコードを作成しようとして競合する
# resource "aws_route53_record" "this" {
#   zone_id = var.zone_id
#   name    = "_amazonses.${aws_ses_domain_identity.this.domain}"
#   type    = "TXT"
#   ttl     = "600"
#   records = [aws_ses_domain_identity.this.verification_token]
#   allow_overwrite = true
# }

resource "aws_ses_domain_dkim" "this" {
  domain = aws_ses_domain_identity.this.domain
}

data "aws_region" "current" {}

resource "aws_route53_record" "this" {
  count   = 3
  zone_id = var.zone_id
  name    = "${aws_ses_domain_dkim.this.dkim_tokens[count.index]}._domainkey"
  type    = "CNAME"
  ttl     = "600"
  records = [
    # 大阪はリージョン付きの値にする必要がある
    # https://docs.aws.amazon.com/ja_jp/general/latest/gr/ses.html
    var.region == "ap-northeast-3"
    ? "${aws_ses_domain_dkim.this.dkim_tokens[count.index]}.dkim.${data.aws_region.current.name}.amazonses.com"
    : "${aws_ses_domain_dkim.this.dkim_tokens[count.index]}.dkim.amazonses.com"
  ]

  lifecycle {
    precondition {
      condition     = length(aws_ses_domain_dkim.this.dkim_tokens) == 3
      error_message = "length(aws_ses_domain_dkim.this.dkim_tokens) == 3"
    }
  }
}
