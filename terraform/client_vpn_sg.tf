resource "aws_security_group" "client_vpn_sg" {
  name        = "client-vpn-sg"
  description = "Allow VPN clients to access internal resources"
  vpc_id      = aws_vpc.main.id

  # Inbound rule: allow all traffic from VPN clients
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.client_vpn_cidr]
    description = "Allow traffic from VPN clients"
  }

  # Outbound rule: allow everything
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "client-vpn-sg"
  }
}
