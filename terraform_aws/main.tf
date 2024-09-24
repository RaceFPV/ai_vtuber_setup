
provider "aws" {
  region = "us-east-1"
}

# S3 Bucket for Terraform state storage
resource "aws_s3_bucket" "terraform_state_bucket" {
  bucket = "my-terraform-state-bucket"  # Use a globally unique bucket name
  acl    = "private"
  
  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

# DynamoDB table for state locking
resource "aws_dynamodb_table" "terraform_state_lock" {
  name         = "terraform-state-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

# IAM Role for Lambda to interact with SQS, Polly, and API Gateway
resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda_exec_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# Attach policies to allow Lambda to interact with SQS, Polly, and S3
resource "aws_iam_role_policy_attachment" "lambda_sqs_policy" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSQSFullAccess"
}

resource "aws_iam_role_policy_attachment" "lambda_polly_policy" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonPollyFullAccess"
}

resource "aws_iam_role_policy_attachment" "lambda_s3_policy" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

# SQS Queue for incoming Twitch chat messages
resource "aws_sqs_queue" "twitch_message_queue" {
  name = "twitch_message_queue"
}

# Lambda function triggered by SQS to process messages and interact with GPT-4 and Polly
resource "aws_lambda_function" "twitch_message_processor" {
  function_name = "TwitchMessageProcessor"
  role          = aws_iam_role.lambda_exec_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.9"
  timeout       = 30
  
  source_code_hash = filebase64sha256("lambda_code.zip")
  filename         = "lambda_code.zip"

  environment {
    variables = {
      "GPT_API_KEY" = "YOUR_GPT_API_KEY"
    }
  }
}

# Grant SQS permission to invoke Lambda
resource "aws_lambda_event_source_mapping" "sqs_lambda_mapping" {
  event_source_arn = aws_sqs_queue.twitch_message_queue.arn
  function_name    = aws_lambda_function.twitch_message_processor.function_name
}

# API Gateway to receive incoming Twitch messages
resource "aws_api_gateway_rest_api" "twitch_api" {
  name        = "TwitchMessageAPI"
  description = "API Gateway to receive Twitch messages."
}

# API Gateway Resource (endpoint)
resource "aws_api_gateway_resource" "twitch_resource" {
  rest_api_id = aws_api_gateway_rest_api.twitch_api.id
  parent_id   = aws_api_gateway_rest_api.twitch_api.root_resource_id
  path_part   = "twitch"
}

# API Gateway Method (POST method to receive messages)
resource "aws_api_gateway_method" "twitch_post_method" {
  rest_api_id   = aws_api_gateway_rest_api.twitch_api.id
  resource_id   = aws_api_gateway_resource.twitch_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

# API Gateway Integration with SQS
resource "aws_api_gateway_integration" "twitch_integration" {
  rest_api_id = aws_api_gateway_rest_api.twitch_api.id
  resource_id = aws_api_gateway_resource.twitch_resource.id
  http_method = aws_api_gateway_method.twitch_post_method.http_method
  integration_http_method = "POST"
  type        = "AWS_PROXY"
  uri         = aws_sqs_queue.twitch_message_queue.arn
}

# Deploy the API
resource "aws_api_gateway_deployment" "twitch_deployment" {
  rest_api_id = aws_api_gateway_rest_api.twitch_api.id
  stage_name  = "prod"
}

# S3 Backend configuration
terraform {
  backend "s3" {
    bucket         = "my-terraform-state-bucket"
    key            = "path/to/my/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}