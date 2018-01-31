resource "aws_iam_role" "lambda_indexer" {
  name = "${var.project_name}_lambda_indexer"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": [
          "lambda.amazonaws.com",
          "apigateway.amazonaws.com"
        ]
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

resource "aws_iam_role_policy" "dynamo-lambda" {
    name = "${var.project_name}-dynamo-policy"
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

resource "aws_iam_role_policy" "s3-lambda" {
    name = "${var.project_name}-s3-policy"
    role = "${aws_iam_role.lambda_indexer.id}"
    policy = <<EOF
{
    "Version": "2008-10-17",
    "Statement": [
        {
            "Action": "s3:*",
            "Effect": "Allow",
            "Resource": [
              "${aws_s3_bucket.raw_html_files.arn}",
              "${aws_s3_bucket.raw_html_files.arn}/*"
            ],
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
  environment {
    variables = {
      LAST_CRAWLED_TABLE = "${aws_dynamodb_table.crawlexa_last_crawled.name}"
      RAW_BUCKET = "${aws_s3_bucket.raw_html_files.bucket}"
    }
  }
}

resource "aws_lambda_permission" "apigw_lambda_indexer" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.indexer.arn}"
  principal     = "apigateway.amazonaws.com"

  # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
  source_arn = "arn:aws:execute-api:${var.project_region}:${var.project_accountId}:${aws_api_gateway_rest_api.crawler_api.id}/*/${aws_api_gateway_method.crawler_api_method.http_method}${aws_api_gateway_resource.crawler_api_resource.path}"
}
