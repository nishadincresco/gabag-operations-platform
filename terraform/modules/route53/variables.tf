variable "domain_name" {
  type = string
}

variable "alb_dns_name" {
  type    = string
  default = null
}

variable "alb_zone_id" {
  type    = string
  default = null
}

variable "record_name" {
  type        = string
  default     = ""
  description = "The name of the record. Leave empty for the root domain."
}

variable "ip_address" {
  type        = string
  default     = null
  description = "The IP address for an A record. Use instead of ALB if pointing to EC2 directly."
}

variable "create_zone" {
  type    = bool
  default = true
}

variable "zone_id" {
  type        = string
  default     = null
  description = "Existing zone ID to use if create_zone is false."
}

variable "common_tags" {
  type = map(string)
}
