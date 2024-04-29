resource "aws_lambda_function" "analyze_lambda" {
  function_name = "analyzeLambdaFunction"

  
  handler = "lambda_function.lambda_handler"
  runtime = "python3.8"


  filename         = "lambda_function/lambda_function.zip"
  source_code_hash = filebase64sha256("lambda_function/lambda_function.zip")
  timeout = 10  # Increase as needed


  # IAM role that the Lambda function will assume
  role = aws_iam_role.lambda_exec_role.arn
  
}

resource "aws_lambda_permission" "api_gateway_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.analyze_lambda.arn
  principal     = "apigateway.amazonaws.com"

  # Important: Specify the source ARN for the API Gateway stage that will invoke this Lambda
 source_arn = "${aws_api_gateway_rest_api.ComprehendApiGateway.execution_arn}/*/*/analyze"
}

