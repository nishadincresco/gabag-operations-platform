output "db_endpoint" {
  description = "RDS host:port — same for dev and prod"
  value       = module.rds.db_endpoint
}

output "db_username" {
  value = var.db_username
}

output "dev_database_name" {
  value = var.dev_database_name
}

output "prod_database_name" {
  value = var.prod_database_name
}

output "vpc_id" {
  value = module.vpc.vpc_id
}
