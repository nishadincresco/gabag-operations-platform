variable "aws_region" {
  type    = string
  default = "eu-west-1"
}

variable "backup_region" {
  type    = string
  default = "eu-west-1"
}

variable "db_username" {
  type    = string
  default = "postgres"
}

variable "db_password" {
  type      = string
  sensitive = true
  validation {
    condition     = length(var.db_password) >= 8 && !can(regex("[/@\" ]", var.db_password))
    error_message = "db_password must be at least 8 characters and must not contain '/', '@', '\"', or spaces (RDS restriction)."
  }
}

variable "dev_database_name" {
  type        = string
  description = "Logical database for dev / local (CREATE DATABASE on shared instance)"
  default     = "gabag_operations_platform_dev"
}

variable "prod_database_name" {
  type        = string
  description = "Logical database for prod (CREATE DATABASE on shared instance)"
  default     = "gabag_operations_platform_prod"
}

variable "rds_instance_class" {
  type    = string
  default = "db.t4g.small"
}

variable "rds_allocated_storage" {
  type    = number
  default = 50
}

variable "rds_max_allocated_storage" {
  type    = number
  default = 200
}

variable "rds_multi_az" {
  type    = bool
  default = false
}

variable "rds_publicly_accessible" {
  type    = bool
  default = true
}

variable "rds_allowed_cidr_blocks" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}

variable "rds_backup_retention_period" {
  type    = number
  default = 14
}

variable "rds_deletion_protection" {
  type    = bool
  default = true
}

variable "rds_skip_final_snapshot" {
  type    = bool
  default = false
}
