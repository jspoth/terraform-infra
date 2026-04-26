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

resource "aws_route53_health_check" "dr" {
  fqdn              = var.healthcheck_domain
  port              = 443
  type              = "HTTPS"
  resource_path     = "/health/live"
  failure_threshold = 3
  request_interval  = 30

  tags = {
    Name = "dr-alb-health-check"
  }
}

resource "aws_route53_record" "this" {
  for_each = toset(var.dns_records)

  zone_id        = data.aws_route53_zone.this.zone_id
  name           = each.value
  type           = "A"
  set_identifier = "secondary"

  failover_routing_policy {
    type = "SECONDARY"
  }

  alias {
    name                   = data.aws_lb.go_app.dns_name
    zone_id                = data.aws_lb.go_app.zone_id
    evaluate_target_health = true
  }
}

output "alb_dns_name" {
  value = data.aws_lb.go_app.dns_name
}
