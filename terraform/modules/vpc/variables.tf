variable "vpc_cidr" {
  type = string
}

variable "name_suffix" {
  type = string
}

variable "common_tags" {
  type = map(string)
}

variable "availability_zones" {
  type = list(string)
}

