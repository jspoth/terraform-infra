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

resource "aws_acm_certificate" "this" {
  domain_name       = var.domain
  validation_method = "DNS"

  subject_alternative_names = ["*.${var.domain}"]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.this.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }

  zone_id         = data.aws_route53_zone.this.zone_id
  name            = each.value.name
  type            = each.value.type
  ttl             = 60
  records         = [each.value.record]
  allow_overwrite = true
}

resource "aws_acm_certificate_validation" "this" {
  certificate_arn         = aws_acm_certificate.this.arn
  validation_record_fqdns = [for r in aws_route53_record.cert_validation : r.fqdn]
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

output "acm_cert_arn" {
  value = aws_acm_certificate.this.arn
}
