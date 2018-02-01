resource "aws_dynamodb_table" "crawlexa_last_crawled" {
  name           = "${var.project_name}_last_crawled"
  read_capacity  = 1000
  write_capacity = 25
  hash_key       = "url_hash"

  attribute {
    name = "url_hash"
    type = "S"
  }

  tags {
    project     = "${var.project_name}"
    environment = "production"
  }
}

