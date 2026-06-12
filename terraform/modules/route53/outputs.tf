output "zone_id" {
  value = local.zone_id
}

output "name_servers" {
  value = var.create_zone ? aws_route53_zone.main[0].name_servers : null
}
