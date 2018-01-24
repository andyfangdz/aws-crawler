resource "aws_iam_role" "lambda_indexer" {
  name = "${var.project_name}_lambda_indexer"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

# Attach role to Managed Policy
resource "aws_iam_policy_attachment" "indexer_basicexec" {
  name = "${var.project_name}_indexer_LambdaExecPolicy"
  roles = ["${aws_iam_role.lambda_indexer.id}"]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "s3-dynamo-lambda" {
    name = "dynamo-policy"
    role = "${aws_iam_role.lambda_indexer.id}"
    policy = <<EOF
{
    "Version": "2008-10-17",
    "Statement": [
        {
            "Action": "dynamodb:*",
            "Effect": "Allow",
            "Resource": "${aws_dynamodb_table.crawlexa_last_crawled.arn}",
            "Sid": ""
        }
    ]
}
EOF
}

data "archive_file" "src_zip" {
  type        = "zip"
  source_dir  = "../build"
  output_path = "build/lambda-src.zip"
}

resource "aws_lambda_function" "indexer" {
  filename         = "${data.archive_file.src_zip.output_path}"
  function_name    = "${var.project_name}_indexer"
  role             = "${aws_iam_role.lambda_indexer.arn}"
  handler          = "indexer.handler"
  source_code_hash = "${base64sha256(file("${data.archive_file.src_zip.output_path}"))}"
  runtime          = "python3.6"
}
