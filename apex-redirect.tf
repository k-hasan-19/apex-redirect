provider "aws" {
  region  = "us-east-1"
  version = "~> 2.70"
}

variable "domain" {
  type        = string
  description = "The domain to redirect from"
  # default = "example.io"
}

variable "redirect_to_domain" {
  type = string
  # default = "example.app"
  description = "The domain to redirect to"
}

data "aws_iam_policy_document" "s3_public_read_policy" {
  statement {
    sid       = 1
    actions   = ["s3:GetObject"]
    resources = ["arn:aws:s3:::${var.domain}/*"]
    principals {
      type        = "*"
      identifiers = ["*"]
    }
  }
}

resource "aws_s3_bucket" "domain_bucket" {
  bucket = var.domain
  # acl = "public-read"
  policy = data.aws_iam_policy_document.s3_public_read_policy.json
  website {
    redirect_all_requests_to = "https://www.${var.redirect_to_domain}"
  }
}

resource "aws_route53_record" "s3_site" {
  zone_id = data.aws_route53_zone.domain_zone_details.zone_id
  name    = var.domain
  type    = "A"
  alias {
    name                   = aws_s3_bucket.domain_bucket.website_domain
    zone_id                = aws_s3_bucket.domain_bucket.hosted_zone_id
    evaluate_target_health = false
  }
}

data "aws_route53_zone" "domain_zone_details" {

  name = var.domain
}
