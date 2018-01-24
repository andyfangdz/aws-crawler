resource "aws_api_gateway_rest_api" "crawler_api" {
  name = "${var.project_name}_API"
}

resource "aws_api_gateway_resource" "crawler_api_resource" {
  rest_api_id = "${aws_api_gateway_rest_api.crawler_api.id}"
  parent_id   = "${aws_api_gateway_rest_api.crawler_api.root_resource_id}"
  path_part   = "crawl"
}

resource "aws_api_gateway_method" "crawler_api_method" {
  rest_api_id   = "${aws_api_gateway_rest_api.crawler_api.id}"
  resource_id   = "${aws_api_gateway_resource.crawler_api_resource.id}"
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "crawler_api_method-integration" {
  rest_api_id = "${aws_api_gateway_rest_api.crawler_api.id}"
  resource_id = "${aws_api_gateway_resource.crawler_api_resource.id}"
  http_method = "${aws_api_gateway_method.crawler_api_method.http_method}"
  type = "AWS_PROXY"
  uri = "arn:aws:apigateway:${var.project_region}:lambda:path/2015-03-31/functions/${aws_lambda_function.indexer.arn}/invocations"
  integration_http_method = "POST"
}

resource "aws_api_gateway_deployment" "crawler_deployment_prod" {
  depends_on = [
    "aws_api_gateway_method.crawler_api_method",
    "aws_api_gateway_integration.crawler_api_method-integration"
  ]
  rest_api_id = "${aws_api_gateway_rest_api.crawler_api.id}"
  stage_name = "api"
}

output "prod_url" {
  value = "https://${aws_api_gateway_deployment.crawler_deployment_prod.rest_api_id}.execute-api.${var.project_region}.amazonaws.com/${aws_api_gateway_deployment.crawler_deployment_prod.stage_name}"
}
