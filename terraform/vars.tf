
variable "db_port" {
  description = "The port PostgreSQL is running on"
  type        = number
}

variable "db_name" {
  description = "Name of the database"
  type        = string
}

variable "db_user" {
  description = "Username for the RDS PostgreSQL database"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Password for the RDS PostgreSQL database"
  type        = string
  sensitive   = true
}

variable "table_name" {
  description = "Name of the production prices table"
  type        = string
}

variable "client_vpn_cidr" {
  description = "The CIDR block for the Client VPN endpoint"
  type        = string
}

variable "aws_region" {
  type    = string
}

variable "account_id" {
  type = string
}

variable "az_a" {
  description = "First availability zone for both private and public subnets"
  type = string
}

variable "az_b" {
  description = "Second availability zone for both private and public subnets"
  type = string
}
