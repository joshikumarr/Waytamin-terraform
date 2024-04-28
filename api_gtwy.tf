resource "aws_api_gateway_rest_api" "MyApiGateway" {
  name        = "BedrockAPIGateway"
  description = "API gateway for the /analyze endpoint"
}