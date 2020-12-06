provider "aws" {
  region  = "eu-west-1"
  profile = "default"
}

variable "suffix" {
  type = string
}


resource "aws_s3_bucket" "bucket_lambda" {
  bucket = "sp-public-tutorial-lambda-builds-${var.suffix}"
  acl    = "private"

tags = {
  Name        = "My bucket for lambda code"
  Project = "Simple lamdba layer with terraform"
  Environment = "Dev"
  }
}


resource "aws_s3_bucket" "bucketf" {
  bucket = "sp-public-tutorial-bucket-source-${var.suffix}"
  acl    = "private"

  tags = {
    Name        = "My source bucket"
    Project = "Simple lamdba layer with terraform"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket" "buckewtB" {
  bucket = "sp-public-tutorial-bucket-target-${var.suffix}"
  acl    = "private"

  tags = {
    Name        = "My target bucket"
    Project = "Simple lamdba layer with terraform"
    Environment = "Dev"
  }
}



module "lambda_function" {
  source = "terraform-aws-modules/lambda/aws"

  function_name = "lambda-with-layer"
  description   = "My awesome lambda function"
  handler       = "lambda_function.lambda_handler"
  lambda_role          = aws_iam_role.iam_for_lambda.arn

  runtime       = "python3.8"
  publish       = true

  source_path = "../python/lambda"

  store_on_s3 = true
  s3_bucket   = "sp-public-tutorial-lambda-builds-${var.suffix}"

  layers = [
    module.lambda_layer_s3.this_lambda_layer_arn,
  ]

  environment_variables = {
    Serverless = "Terraform"
  }

  tags = {
    Name        = "My lambda layer"
    Project = "Simple lamdba layer with terraform"
    Environment = "Dev"
  }

  depends_on = [aws_s3_bucket.bucket_lambda]
}

module "lambda_layer_s3" {
  source = "terraform-aws-modules/lambda/aws"

  create_layer = true

  layer_name          = "lambda-layer-s3"
  description         = "My amazing lambda layer (deployed from S3)"
  compatible_runtimes = ["python3.8"]

  source_path = "../python/layer"

  store_on_s3 = true
  s3_bucket   = "sp-public-tutorial-lambda-builds-${var.suffix}"

  tags = {
    Name        = "My lambda layer"
    Project = "Simple lamdba layer with terraform"
    Environment = "Dev"
  }
  depends_on = [aws_s3_bucket.bucket_lambda]
}

resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda"

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

# resource "aws_cloudwatch_log_group" "example" {
#   name              = "/aws/lambda/${var.lambda_function_name}"
#   retention_in_days = 1
# }

# See also the following AWS managed policy: AWSLambdaBasicExecutionRole
resource "aws_iam_policy" "lambda_logging" {
  name        = "lambda_logging"
  path        = "/"
  description = "IAM policy for logging from a lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    },
        {
      "Action": [
        "s3:ListBucket",
        "s3:GetObject",
        "s3:PutObject"
      ],
      "Resource": "arn:aws:s3:::*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}