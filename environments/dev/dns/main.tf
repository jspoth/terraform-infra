data "aws_route53_zone" "this" {
  name         = var.domain
  private_zone = false
}

data "aws_lb" "go_app" {
  tags = {
    "elbv2.k8s.aws/cluster" = var.cluster_name
    "ingress.k8s.aws/stack" = "default/${var.ingress_name}"
  }
}

resource "aws_route53_health_check" "primary" {
  fqdn              = var.healthcheck_domain
  port              = 443
  type              = "HTTPS"
  resource_path     = "/health/live"
  failure_threshold = 3
  request_interval  = 30

  tags = {
    Name = "primary-alb-health-check"
  }
}

resource "aws_route53_record" "this" {
  for_each = toset(var.dns_records)

  zone_id         = data.aws_route53_zone.this.zone_id
  name            = each.value
  type            = "A"
  set_identifier  = "primary"
  health_check_id = aws_route53_health_check.primary.id

  failover_routing_policy {
    type = "PRIMARY"
  }

  alias {
    name                   = data.aws_lb.go_app.dns_name
    zone_id                = data.aws_lb.go_app.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "github_pages" {
  zone_id = data.aws_route53_zone.this.zone_id
  name    = var.domain
  type    = "A"
  ttl     = 300
  records = var.github_pages_ips
}

output "alb_dns_name" {
  value = data.aws_lb.go_app.dns_name
}
