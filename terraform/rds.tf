# Create a security group that allows inbound Postgres traffic (port 5432)
resource "aws_security_group" "rds_sg" {
  name        = "rds_sg"
  description = "Allow PostgreSQL access"
  vpc_id      = aws_vpc.main.id

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

# Providing rds_sg ingress rule separately to avoid
# circular dependency issues with lambda_sg
resource "aws_security_group_rule" "rds_allow_lambda" {
  type              = "ingress"
  from_port         = 5432
  to_port           = 5432
  protocol          = "tcp"
  security_group_id = aws_security_group.rds_sg.id
  source_security_group_id = aws_security_group.lambda_sg.id
}

# Providing local DB access
resource "aws_security_group_rule" "rds_allow_pgadmin" {
  type              = "ingress"
  from_port         = 5432
  to_port           = 5432
  protocol          = "tcp"
  security_group_id = aws_security_group.rds_sg.id
  cidr_blocks       = [var.local_ip]
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
  db_name                 = "cryptoetl"
  username                = var.db_user
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
