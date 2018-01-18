provider "aws" {
  region = "us-east-1"
}

resource "aws_sqs_queue" "crawl-jobs" {
  name = "${var.project_name}-jobs"

  tags {
    project     = "${var.project_name}"
    environment = "production"
  }
}
