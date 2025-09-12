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
  region = var.aws_region
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
  filename         = "${path.module}/../lambda_build.zip"
  source_code_hash = filebase64sha256("${path.module}/../lambda_build.zip")

  memory_size = 128
  timeout     = 30

    vpc_config {
    subnet_ids         = [aws_subnet.private_a.id, aws_subnet.private_b.id]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

   environment {
    variables = {
      CRYPTO_DATA_BUCKET = aws_s3_bucket.crypto_data_bucket.bucket
      DB_HOST            = aws_db_instance.crypto_etl_db.address
      DB_PORT            = var.db_port
      DB_USER            = var.db_user
      DB_PASSWORD        = var.db_password
      DB_NAME            = var.db_name
      TABLE_NAME         = var.table_name
    }
  }
}

# Security Group for Lambda function to control its network access inside the VPC.
resource "aws_security_group" "lambda_sg" {
  name   = "lambda_sg"
  vpc_id = aws_vpc.main.id
}

# Providing lambda_sg egress rule separately to avoid
# circular dependency issues with rds_sg
resource "aws_security_group_rule" "lambda_allow_all_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.lambda_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
}

