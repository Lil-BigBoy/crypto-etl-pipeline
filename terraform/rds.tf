# Create a security group that allows inbound Postgres traffic (port 5432)
resource "aws_security_group" "rds_sg" {
  name        = "rds_sg"
  description = "Allow PostgreSQL access"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["150.143.99.133/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rds_sg"
  }
}

# Subnet group for RDS
resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "rds-subnet-group"
  subnet_ids = [aws_subnet.public_a.id, aws_subnet.public_b.id]

  tags = {
    Name = "rds-subnet-group"
  }
}

# PostgreSQL parameter group
resource "aws_db_parameter_group" "postgresql_parameters" {
  name        = "postgresql-params"
  family      = "postgres14"
  description = "Custom parameter group for PostgreSQL"

  parameter {
    name  = "log_connections"
    value = "1"
  }
}

# RDS instance (PostgreSQL)
resource "aws_db_instance" "crypto_etl_db" {
  identifier              = "crypto-etl-db"
  allocated_storage       = 20
  storage_type            = "gp2"
  engine                  = "postgres"
  engine_version          = "14.17"
  instance_class          = "db.t3.micro"
  db_name                    = "cryptoetl"
  username                = var.db_username
  password                = var.db_password
  db_subnet_group_name    = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids  = [aws_security_group.rds_sg.id]
  publicly_accessible     = true
  parameter_group_name    = aws_db_parameter_group.postgresql_parameters.name
  skip_final_snapshot     = true

  tags = {
    Name = "crypto-etl-db"
  }
}
