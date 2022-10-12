terraform {
  backend "remote" {
    organization = "purbo75"

    workspaces {
      name = "lamda-func"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>4.34"
    }

  }
}

provider "aws" {
  region = "eu-west-1"
}
resource "aws_iam_role" "lambda_role" {
  name               = "Spacelift_Test_Lambda_Function_Role"
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

resource "aws_iam_policy" "iam_policy_for_lambda" {

  name        = "aws_iam_policy_for_terraform_aws_lambda_role"
  path        = "/"
  description = "AWS IAM Policy for managing aws lambda role"
  policy      = <<EOF
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
   }
 ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "attach_iam_policy_to_iam_role" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.iam_policy_for_lambda.arn
}

data "archive_file" "zip_the_golang_code" {
  type        = "zip"
  source_dir  = "${path.module}/golang/"
  output_path = "${path.module}/golang/go-lambda.zip"
}

resource "aws_lambda_function" "aws_lambda_function" {
  filename         = "${path.module}/golang/go-lambda.zip"
  function_name    = "goLambdaDemo"
  role             = aws_iam_role.lambda_role.arn
  handler          = "main"
  source_code_hash = sha256(filebase64("${path.module}/golang/go-lambda.zip"))
  runtime          = "go1.x"
  depends_on       = [aws_iam_role_policy_attachment.attach_iam_policy_to_iam_role]
}

