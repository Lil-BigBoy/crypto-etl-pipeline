
# --------------------
# Permanent User - terraform-crypto-etl
# --------------------

resource "aws_iam_user" "terraform_crypto_etl" {
  name = "terraform-crypto-etl"
}

# Read-only CloudWatch Logs for viewing Lambda logs
resource "aws_iam_user_policy_attachment" "cloudwatch_logs_readonly" {
  user       = aws_iam_user.terraform_crypto_etl.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsReadOnlyAccess"
}

# Allow configuration of EventBridge schedule frequency
resource "aws_iam_user_policy" "crypto_etl_policy" {
  name = "crypto-etl-policy"
  user = aws_iam_user.terraform_crypto_etl.name

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "events:PutRule"
        ],
        "Resource": "arn:aws:events:${var.aws_region}:${var.aws_account}:rule/crypto-etl-schedule"
      }
    ]
  })
}

# Secondary read-only permissions needed to run TF plan/apply when changing EB schedule
resource "aws_iam_policy" "readonly_policy" {
  name   = "terraform-crypto-etl-readonly"
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "AllowSTSGetCallerIdentity",
        "Effect": "Allow",
        "Action": [
          "sts:GetCallerIdentity"
        ],
        "Resource": "*"
      },
      {
        "Sid": "IAMReadOnly",
        "Effect": "Allow",
        "Action": [
          "iam:GetUser",
          "iam:GetRole",
          "iam:GetPolicy",
          "iam:GetRolePolicy",
          "iam:GetUserPolicy",
          "iam:GetPolicyVersion",
          "iam:GetAccountAuthorizationDetails",
          "iam:GetAccountPasswordPolicy",
          "iam:GetAccountSummary",
          "iam:GetGroup",
          "iam:GetGroupPolicy",
          "iam:GetServerCertificate",
          "iam:GetServiceLinkedRoleDeletionStatus",
          "iam:ListRoles",
          "iam:ListUsers",
          "iam:ListPolicies",
          "iam:ListAttachedRolePolicies",
          "iam:ListAttachedUserPolicies",
          "iam:ListRolePolicies",
          "iam:ListUserPolicies",
          "iam:ListGroups",
          "iam:ListGroupsForUser",
          "iam:ListServerCertificates",
          "iam:ListInstanceProfiles",
          "iam:ListAccountAliases"
        ],
        "Resource": "*"
      },
      {
        "Sid": "EC2DescribeOnly",
        "Effect": "Allow",
        "Action": [
          "ec2:DescribeVpcs",
          "ec2:DescribeVpcAttribute",
          "ec2:DescribeAddressesAttribute",
          "ec2:DescribeSubnets",
          "ec2:DescribeRouteTables",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeAddresses",
          "ec2:DescribeNatGateways",
          "ec2:DescribeInternetGateways",
          "ec2:DescribeNetworkAcls",
          "ec2:DescribeInstances",
          "ec2:DescribeTags",
          "ec2:DescribeSecurityGroupRules",
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeImages",
          "ec2:DescribeKeyPairs",
          "ec2:DescribeVolumes",
          "ec2:DescribeSnapshots",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribeInternetGateways",
          "ec2:DescribeEgressOnlyInternetGateways",
          "ec2:DescribeCustomerGateways",
          "ec2:DescribeVpnGateways",
          "ec2:DescribeVpnConnections",
          "ec2:DescribeDhcpOptions",
          "ec2:DescribeFlowLogs",
          "ec2:DescribeSecurityGroupReferences",
          "ec2:DescribeVpcPeeringConnections",
          "ec2:DescribeTransitGateways",
          "ec2:DescribeTransitGatewayAttachments",
          "ec2:DescribeTransitGatewayRouteTables"
        ],
        "Resource": "*"
      },
      {
        "Sid": "RDSDescribeOnly",
        "Effect": "Allow",
        "Action": [
          "rds:Describe*",
          "rds:ListTagsForResource",
          "rds:DescribeDBInstances",
          "rds:DescribeDBParameterGroups",
          "rds:DescribeDBParameters",
          "rds:DescribeDBSubnetGroups",
          "rds:DescribeDBSecurityGroups",
          "rds:DescribeDBLogFiles",
          "rds:DownloadDBLogFilePortion",
          "rds:DescribeEvents",
          "rds:DescribeOptionGroups",
          "rds:DescribeOrderableDBInstanceOptions",
          "rds:DescribeReservedDBInstances",
          "rds:DescribeReservedDBInstancesOfferings",
          "rds:DescribeDBEngineVersions",
          "rds:DescribeCertificates",
          "rds:DescribeDBClusterParameterGroups",
          "rds:DescribeDBClusterParameters",
          "rds:DescribeDBClusters",
          "rds:DescribeDBClusterEndpoints",
          "rds:DescribeDBClusterSnapshotAttributes",
          "rds:DescribeDBClusterSnapshots",
          "rds:DescribePendingMaintenanceActions",
          "rds:ListTagsForResource"
        ],
        "Resource": "*"
      },
      {
        "Sid": "S3BucketRead",
        "Effect": "Allow",
        "Action": [
          "s3:GetAccelerateConfiguration",
          "s3:GetAnalyticsConfiguration",
          "s3:GetBucketAcl",
          "s3:GetBucketCORS",
          "s3:GetBucketLocation",
          "s3:GetBucketLogging",
          "s3:GetBucketNotification",
          "s3:GetBucketObjectLockConfiguration",
          "s3:GetBucketPolicy",
          "s3:GetBucketPolicyStatus",
          "s3:GetBucketPublicAccessBlock",
          "s3:GetBucketReplication",
          "s3:GetBucketRequestPayment",
          "s3:GetBucketTagging",
          "s3:GetBucketVersioning",
          "s3:GetBucketWebsite",
          "s3:GetEncryptionConfiguration",
          "s3:GetInventoryConfiguration",
          "s3:GetLifecycleConfiguration",
          "s3:GetMetricsConfiguration",
          "s3:GetObject",
          "s3:GetObjectAcl",
          "s3:GetObjectLegalHold",
          "s3:GetObjectRetention",
          "s3:GetObjectTagging",
          "s3:GetObjectVersion",
          "s3:GetObjectVersionAcl",
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectVersionTagging",
          "s3:GetReplicationConfiguration",
          "s3:ListAllMyBuckets",
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads",
          "s3:ListBucketVersions",
          "s3:ListMultipartUploadParts"
        ],
        "Resource": "*"
      },
      {
        "Sid": "LambdaReadOnly",
        "Effect": "Allow",
        "Action": [
          "lambda:GetAccountSettings",
          "lambda:GetAlias",
          "lambda:GetEventSourceMapping",
          "lambda:GetFunction",
          "lambda:GetFunctionConfiguration",
          "lambda:GetFunctionCodeSigningConfig",
          "lambda:GetFunctionConcurrency",
          "lambda:GetFunctionEventInvokeConfig",
          "lambda:GetPolicy",
          "lambda:ListAliases",
          "lambda:ListEventSourceMappings",
          "lambda:ListFunctions",
          "lambda:ListFunctionEventInvokeConfigs",
          "lambda:ListTags",
          "lambda:ListVersionsByFunction"
        ],
        "Resource": "*"
      },
      {
        "Sid": "EventBridgeReadOnly",
        "Effect": "Allow",
        "Action": [
          "events:DescribeArchive",
          "events:DescribeEventBus",
          "events:DescribeRule",
          "events:ListArchives",
          "events:ListEventBuses",
          "events:ListEventSources",
          "events:ListPartnerEventSourceAccounts",
          "events:ListPartnerEventSources",
          "events:ListRuleNamesByTarget",
          "events:ListRules",
          "events:ListTargetsByRule",
          "events:ListTagsForResource"
        ],
        "Resource": "*"
      },
      {
        "Sid": "CloudWatchReadOnly",
        "Effect": "Allow",
        "Action": [
          "cloudwatch:DescribeAlarmHistory",
          "cloudwatch:DescribeAlarms",
          "cloudwatch:DescribeAlarmsForMetric",
          "cloudwatch:DescribeInsightRules",
          "cloudwatch:GetDashboard",
          "cloudwatch:GetInsightRuleReport",
          "cloudwatch:GetMetricData",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListDashboards",
          "cloudwatch:ListMetrics",
          "cloudwatch:ListTagsForResource"
        ],
        "Resource": "*"
      }
    ]
  })
}
resource "aws_iam_user_policy_attachment" "attach_readonly_policy" {
  user       = aws_iam_user.terraform_crypto_etl.name
  policy_arn = aws_iam_policy.readonly_policy.arn
}

# Allow invocation/ viewing of the lambda
resource "aws_iam_user_policy" "crypto_etl_lambda_invoke" {
  name = "crypto-etl-lambda-invoke"
  user = aws_iam_user.terraform_crypto_etl.name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "lambda:InvokeFunction",
          "lambda:GetFunction",
          "lambda:GetFunctionConfiguration"
        ],
        Resource = "arn:aws:lambda:${var.aws_region}:${var.aws_account}:function:crypto-etl-lambda"
      }
    ]
  })
}

# --------------------
# Lambda Execution Role
# --------------------

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

# Allow Logging
resource "aws_iam_role_policy_attachment" "lambda_logging" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Specifying where Lambda can put
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
          "${aws_s3_bucket.crypto_data_bucket.arn}/raw/*",
          "${aws_s3_bucket.crypto_data_bucket.arn}/processed/*"
        ]
      }
    ]
  })
}
resource "aws_iam_role_policy_attachment" "lambda_s3_put" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.lambda_s3_put_policy.arn
}

# Allowing self designation of Elastic Network Interface
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
