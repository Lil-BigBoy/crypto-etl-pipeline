resource "aws_iam_user" "terraform_crypto_etl" {
  name = "terraform-crypto-etl"
}

resource "aws_iam_user_policy_attachment" "s3_full_access" {
  user       = aws_iam_user.terraform_crypto_etl.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_user_policy_attachment" "lambda_full_access" {
  user       = aws_iam_user.terraform_crypto_etl.name
  policy_arn = "arn:aws:iam::aws:policy/AWSLambda_FullAccess"
}

resource "aws_iam_user_policy_attachment" "cloudwatch_full_access" {
  user       = aws_iam_user.terraform_crypto_etl.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchFullAccess"
}

// !!!WARNING!!! - Had to be provided via console even thouh the necessary actions are also added to the inline policy- Needs revisiting
resource "aws_iam_user_policy_attachment" "eventbridge_full_access" {
  user       = aws_iam_user.terraform_crypto_etl.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEventBridgeFullAccess"
}

resource "aws_iam_user_policy_attachment" "iam_full_access" {
  user       = aws_iam_user.terraform_crypto_etl.name
  policy_arn = "arn:aws:iam::aws:policy/IAMFullAccess"
}

resource "aws_iam_user_policy" "crypto_etl_policy" {
  name = "crypto-etl-policy"
  user = aws_iam_user.terraform_crypto_etl.name

  policy = jsonencode({
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "events:PutRule",
        "events:PutTargets",
        "events:DescribeRule",
        "events:ListTagsForResource",
        "lambda:AddPermission"
      ],
      "Resource": "*"
    }
  ]
})
}

resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Effect = "Allow"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_logging" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

