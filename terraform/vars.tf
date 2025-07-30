
variable "db_host" {
  description = "The hostname or endpoint of the PostgreSQL database"
  type        = string
}

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
