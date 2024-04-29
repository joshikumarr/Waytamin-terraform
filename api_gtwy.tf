# Create the API Gateway to interface with AWS Comprehend via Lambda
resource "aws_api_gateway_rest_api" "ComprehendApiGateway" {
  name        = "ComprehendApiGateway"
  description = "API Gateway for the /analyze endpoint, interfacing with AWS Comprehend"
}

# Create a resource within the API Gateway for the /analyze endpoint
resource "aws_api_gateway_resource" "analyze_resource" {
  rest_api_id = aws_api_gateway_rest_api.ComprehendApiGateway.id
  parent_id   = aws_api_gateway_rest_api.ComprehendApiGateway.root_resource_id
  path_part   = "analyze"
}

# Define the POST method for the /analyze endpoint
resource "aws_api_gateway_method" "analyze_method" {
  rest_api_id   = aws_api_gateway_rest_api.ComprehendApiGateway.id
  resource_id   = aws_api_gateway_resource.analyze_resource.id
  http_method   = "POST"
  authorization = "NONE"  # No authorization required
}

# Set up the integration between the API Gateway and the Lambda function
resource "aws_api_gateway_integration" "analyze_integration" {
  rest_api_id = aws_api_gateway_rest_api.ComprehendApiGateway.id
  resource_id = aws_api_gateway_resource.analyze_resource.id
  http_method = aws_api_gateway_method.analyze_method.http_method

  type                      = "AWS_PROXY"
  integration_http_method   = "POST"
  uri                       = aws_lambda_function.analyze_lambda.invoke_arn

}



# CloudWatch logGroup 
resource "aws_cloudwatch_log_group" "api_logs" {
  name = "/aws/apigateway/ComprehendApiGateway-dev"

  # Optionally, you can set the retention in days
  retention_in_days = 14
}

resource "aws_api_gateway_stage" "api_stage" {
  stage_name    = "dev"
  rest_api_id   = aws_api_gateway_rest_api.ComprehendApiGateway.id
  deployment_id = aws_api_gateway_deployment.api_deployment.id

  # Enable AWS X-Ray for tracing
  xray_tracing_enabled = true

  # Access logging settings
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_logs.arn
    format = jsonencode({
    requestId         = "$context.requestId",
    requestTime       = "$context.requestTime",
    httpMethod        = "$context.httpMethod",
    resourcePath      = "$context.resourcePath",
    status            = "$context.status",
    responseLength    = "$context.responseLength",
    ip                = "$context.identity.sourceIp",
    userAgent         = "$context.identity.userAgent",
    integrationStatus = "$context.integration.status",
    integrationLatency = "$context.integration.latency",
    integrationErrorMessage = "$context.integrationErrorMessage",
    errorMessage      = "$context.error.message",
    })
  }
}

resource "aws_api_gateway_deployment" "api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.ComprehendApiGateway.id

  
  description = "Deployment for the ComprehendApiGateway API at ${timestamp()}"

  # This lifecycle block will create a new deployment every time the API is updated
  lifecycle {
    create_before_destroy = true
  }

  # Depends on ensures that changes to the API are deployed
  depends_on = [
    aws_api_gateway_integration.analyze_integration
  ]
}


