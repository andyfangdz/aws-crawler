resource "aws_s3_bucket" "raw_html_files" {
  bucket = "raw.${aws_route53_zone.primary.name}"
  acl    = "private"

  lifecycle_rule {
    id      = "infrequent-access-deprecation"
    enabled = true

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 60
      storage_class = "GLACIER"
    }

    expiration {
      days = 90
    }
  }
}
