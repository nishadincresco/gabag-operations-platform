variable "name_suffix" { type = string }
variable "common_tags" { type = map(string) }
variable "account_id" { type = string }

variable "app_base_url" {
  type        = string
  description = "App origin allowed in S3 CORS policy (e.g. https://dev.example.amplifyapp.com)"
  default     = "*"
}
