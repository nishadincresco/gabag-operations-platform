variable "name_suffix" {
  type = string
}

variable "common_tags" {
  type = map(string)
}

variable "cron_endpoint_url" {
  type        = string
  description = "Base URL of the app (e.g. https://dev.example.com)"
}

variable "cron_secret" {
  type        = string
  description = "Bearer token sent as Authorization header to the cron endpoint"
  sensitive   = true
}

variable "schedule_expression" {
  type    = string
  default = "rate(2 minutes)"
}

variable "api_path" {
  type    = string
  default = "/api/cron"
}
