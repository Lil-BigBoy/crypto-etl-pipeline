variable "db_username" {
  description = "Username for the RDS PostgreSQL database"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Password for the RDS PostgreSQL database"
  type        = string
  sensitive   = true
}
