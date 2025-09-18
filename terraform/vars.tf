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

variable "aws_region" {
  description = "Name of the AWS region"
  type        = string
}

variable "az_a" {
  description = "Name of the first availability zone"
  type        = string
}

variable "az_b" {
  description = "Name of the second availability zone"
  type        = string
}

variable "local_ip" {
  description = "The machine that will be used to connect to the DB for querying"
  type        = string
}
