provider "aws" {
  region = "us-east-1"
}

resource "aws_sqs_queue" "crawlexa-jobs" {
  name = "crawlexa-jobs"

  tags {
    project     = "crawlexa"
    environment = "production"
  }
}

