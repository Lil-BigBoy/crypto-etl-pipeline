resource "aws_cloudwatch_event_rule" "crypto_etl_rule" {
  depends_on = [aws_iam_user_policy.crypto_etl_policy]
  name                = "crypto-etl-schedule"
  schedule_expression = "rate(15 minutes)"
  description         = "Scheduled event to trigger the crypto ETL Lambda function"
}

resource "aws_cloudwatch_event_target" "crypto_etl_target" {
  rule      = aws_cloudwatch_event_rule.crypto_etl_rule.name
  target_id = "crypto_etl_lambda_target"
  arn       = aws_lambda_function.crypto_etl_lambda.arn
}

resource "aws_lambda_permission" "crypto_etl_lambda_permission" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  principal     = "events.amazonaws.com"
  function_name = aws_lambda_function.crypto_etl_lambda.function_name
  source_arn    = aws_cloudwatch_event_rule.crypto_etl_rule.arn
}