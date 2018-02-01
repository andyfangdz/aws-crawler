resource "aws_sns_topic" "to_crawl" {
  name = "${var.project_name}-to_crawl"
}

resource "aws_sns_topic_subscription" "topic_lambda" {
  topic_arn = "${aws_sns_topic.to_crawl.arn}"
  protocol  = "lambda"
  endpoint  = "${aws_lambda_function.indexer.arn}"
}

resource "aws_lambda_permission" "with_sns" {
    statement_id = "AllowExecutionFromSNS"
    action = "lambda:InvokeFunction"
    function_name = "${aws_lambda_function.indexer.arn}"
    principal = "sns.amazonaws.com"
    source_arn = "${aws_sns_topic.to_crawl.arn}"
}
