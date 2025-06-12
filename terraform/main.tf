terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "crypto_data_bucket" {
  bucket = "crypto-etl-pipeline-${random_id.bucket_id.hex}"
  force_destroy = true
}

resource "random_id" "bucket_id" {
  byte_length = 4
}

resource "aws_lambda_function" "crypto_etl_lambda" {
  function_name = "crypto_etl"
  runtime       = "python3.12"
  handler       = "etl.lambda_handler"
  role             = aws_iam_role.lambda_exec_role.arn
  filename         = "${path.module}/../etl.zip"
  source_code_hash = filebase64sha256("${path.module}/../etl.zip")

  memory_size = 128
  timeout     = 30

   environment {
    variables = {
      CRYPTO_DATA_BUCKET = aws_s3_bucket.crypto_data_bucket.bucket
    }
  }
}
