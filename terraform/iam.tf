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
resource "aws_iam_user_policy_attachment" "rds_full_access" {
  user       = aws_iam_user.terraform_crypto_etl.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonRDSFullAccess"
}

resource "aws_iam_user_policy_attachment" "ec2_full_access" {
  user       = aws_iam_user.terraform_crypto_etl.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

// !!!WARNING!!! - Had to be provided via AWS console even though the necessary actions are also added to the inline policy - Needs revisiting
resource "aws_iam_user_policy_attachment" "eventbridge_full_access" {
  user       = aws_iam_user.terraform_crypto_etl.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEventBridgeFullAccess"
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
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateNetworkInterface",
        "ec2:DetachNetworkInterface",
        "ec2:DescribeNetworkInterfaces",
        "ec2:DeleteNetworkInterface"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "acm:ImportCertificate",
        "acm:DeleteCertificate",
        "acm:DescribeCertificate",
        "acm:ListCertificates",
        "acm:ListTagsForCertificate"
      ],
      "Resource": "arn:aws:acm:${var.aws_region}:${var.account_id}:certificate/*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "iam:CreateAccessKey",
        "iam:DeleteAccessKey",
        "iam:ListAccessKeys",
        "iam:GetUser"
      ],
      "Resource": "arn:aws:iam::${var.account_id}:user/terraform-crypto-etl"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateClientVpnEndpoint",
        "ec2:DeleteClientVpnEndpoint",
        "ec2:ModifyClientVpnEndpoint",
        "ec2:DescribeClientVpnEndpoints",
        "ec2:AssociateClientVpnTargetNetwork",
        "ec2:DisassociateClientVpnTargetNetwork",
        "ec2:DescribeClientVpnTargetNetworks",
        "ec2:CreateClientVpnAuthorizationRule",
        "ec2:DeleteClientVpnAuthorizationRule",
        "ec2:AuthorizeClientVpnIngress",
        "ec2:RevokeClientVpnIngress",
        "ec2:DescribeClientVpnAuthorizationRules",
        "ec2:ExportClientVpnClientConfiguration",
        "ec2:DescribeSubnets",
        "ec2:DescribeVpcs",
        "ec2:DescribeSecurityGroups"
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

resource "aws_iam_policy" "lambda_s3_put_policy" {
  name        = "lambda-s3-put-policy"
  description = "Allow Lambda to write to S3"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:PutObject"
        ],
        Resource = [
          "arn:aws:s3:::${aws_s3_bucket.crypto_data_bucket.bucket}/raw/*",
          "arn:aws:s3:::${aws_s3_bucket.crypto_data_bucket.bucket}/processed/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_s3_put" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.lambda_s3_put_policy.arn
}

resource "aws_iam_policy" "lambda_vpc_access_policy" {
  name        = "lambda-vpc-access-policy"
  description = "Allow Lambda to manage ENIs in VPC"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_vpc_access" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.lambda_vpc_access_policy.arn
}

