variable "name_suffix" {
  type = string
}

variable "common_tags" {
  type = map(string)
}

variable "domain" {
  type        = string
  description = "The domain name to use for SES"
}
