variable "name_suffix" {
  type = string
}

variable "common_tags" {
  type = map(string)
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "allowed_security_groups" {
  type    = list(string)
  default = []
}

variable "allowed_cidr_blocks" {
  type    = list(string)
  default = []
}

variable "db_name" {
  type = string
}

variable "db_username" {
  type = string
}

variable "db_password" {
  type      = string
  sensitive = true
  validation {
    condition     = length(var.db_password) >= 8 && !can(regex("[/@\" ]", var.db_password))
    error_message = "db_password must be at least 8 characters and must not contain '/', '@', '\"', or spaces (RDS restriction)."
  }
}

variable "instance_class" {
  type = string
}

variable "allocated_storage" {
  type = number
}

variable "max_allocated_storage" {
  type        = number
  description = "Max storage for autoscaling in GB. Set to 0 to disable autoscaling."
  default     = 0
}

variable "multi_az" {
  type = bool
}

variable "skip_final_snapshot" {
  type = bool
}

variable "backup_retention_period" {
  type = number
}

variable "enable_cross_region_backup" {
  type = bool
}

variable "deletion_protection" {
  type        = bool
  description = "Protect the RDS instance from accidental deletion via terraform destroy."
  default     = false
}

variable "publicly_accessible" {
  type    = bool
  default = false
}
