# Database Host Name
output "db_host" {
  value       = aws_db_instance.crypto_etl_db.address
  description = " DNS name of RDS database endpoint"
}

# S3 Bucket Name
output "crypto_data_bucket" {
  value       = aws_s3_bucket.crypto_data_bucket.bucket
  description = "Name of the S3 bucket used for storing both raw and processed crypto data"
}

# Lambda Function Name
output "crypto_etl_lambda_name" {
  value       = aws_lambda_function.crypto_etl_lambda.function_name
  description = "The name of the deployed Lambda function"
}

# Client VPN endpoint DNS
/*output "client_vpn_endpoint" {
  value       = aws_ec2_client_vpn_endpoint.vpn_endpoint.dns_name
  description = "DNS name of the AWS Client VPN endpoint"
}*/

#----------
# Outputs required to create the Client VPN endpoint via AWS CLI.
#----------

# VPC ID
output "vpc_id" {
  value       = aws_vpc.main.id
  description = "The ID of the VPC for the Client VPN endpoint"
}

# Security Group ID
output "client_vpn_sg_id" {
  value       = aws_security_group.client_vpn_sg.id
  description = "Security Group ID to associate with the VPN endpoint"
}

# Private subnets IDs
output "private_subnet_ids" {
  value = [
    aws_subnet.private_a.id,
    aws_subnet.private_b.id
  ]
  description = "List of private subnet IDs for VPN association"
}

# Client VPN CIDR block
output "client_vpn_cidr" {
  value       = var.client_vpn_cidr
  description = "CIDR block to assign to VPN clients"
}

# File paths for certificates
output "server_cert_path" {
  value       = "certs/server.crt"
  description = "Path to the Server certificate PEM file"
}

output "server_key_path" {
  value       = "certs/server.key"
  description = "Path to the Server private key PEM file"
}

output "root_ca_cert_path" {
  value       = "certs/ca.crt"
  description = "Path to the Root CA certificate PEM file"
}
