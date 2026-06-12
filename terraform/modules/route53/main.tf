resource "aws_route53_zone" "main" {
  count = var.create_zone ? 1 : 0
  name  = var.domain_name
  tags  = var.common_tags
}

locals {
  zone_id = var.create_zone ? aws_route53_zone.main[0].zone_id : var.zone_id
  name    = var.record_name == "" ? var.domain_name : "${var.record_name}.${var.domain_name}"
}

resource "aws_route53_record" "app" {
  count   = (var.alb_dns_name != null || var.ip_address != null) ? 1 : 0
  zone_id = local.zone_id
  name    = local.name
  type    = "A"

  # Use ALIAS if ALB info is provided
  dynamic "alias" {
    for_each = var.alb_dns_name != null ? [1] : []
    content {
      name                   = var.alb_dns_name
      zone_id                = var.alb_zone_id
      evaluate_target_health = true
    }
  }

  # Use records if IP is provided and no ALB
  ttl     = var.alb_dns_name == null ? 300 : null
  records = var.alb_dns_name == null && var.ip_address != null ? [var.ip_address] : null
}
