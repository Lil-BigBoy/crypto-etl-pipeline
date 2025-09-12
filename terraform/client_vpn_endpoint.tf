/*resource "aws_ec2_client_vpn_endpoint" "vpn_endpoint" {
  description            = "Crypto ETL Client VPN"
  server_certificate_arn = var.server_cert_arn
  authentication_options {
    type                       = "certificate-authentication"
    root_certificate_chain_arn = var.server_cert_arn
  }

  client_cidr_block        = var.client_vpn_cidr
  connection_log_options {
    enabled = false  # CloudWatch logging can be enabled later
  }

  security_group_ids       = [aws_security_group.client_vpn_sg.id]
  vpc_id                   = aws_vpc.main.id
  split_tunnel             = true  # Only route VPC traffic through VPN
  #dns_servers              = ["AmazonProvidedDNS"]

  tags = {
    Name = "crypto-etl-client-vpn"
  }
}*/

/*resource "aws_ec2_client_vpn_network_association" "private_a" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.vpn_endpoint.id
  subnet_id              = aws_subnet.private_a.id
}

resource "aws_ec2_client_vpn_network_association" "private_b" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.vpn_endpoint.id
  subnet_id              = aws_subnet.private_b.id
}

resource "aws_ec2_client_vpn_authorization_rule" "vpc_access" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.vpn_endpoint.id
  target_network_cidr    = aws_vpc.main.cidr_block
  authorize_all_groups   = true
  description           = "Allow VPN clients access to VPC"
}

resource "aws_ec2_client_vpn_route" "vpc_route_a" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.vpn_endpoint.id
  destination_cidr_block = aws_vpc.main.cidr_block
  target_vpc_subnet_id   = aws_subnet.private_a.id
}

resource "aws_ec2_client_vpn_route" "vpc_route_b" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.vpn_endpoint.id
  destination_cidr_block = aws_vpc.main.cidr_block
  target_vpc_subnet_id   = aws_subnet.private_b.id
}*/
