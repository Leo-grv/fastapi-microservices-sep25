# ============================================================================
# DATA SOURCE - ZONE ROUTE53 EXISTANTE
# ============================================================================

data "aws_route53_zone" "main" {
  count = var.create_route53_zone ? 0 : 1

  name         = var.domain_name
  private_zone = false
}

# ============================================================================
# ZONE ROUTE53 (si elle n'existe pas déjà)
# ============================================================================

resource "aws_route53_zone" "main" {
  count = var.create_route53_zone ? 1 : 0

  name = var.domain_name

  tags = merge(
    var.tags,
    {
      Name = var.domain_name
    }
  )
}

# Local pour récupérer la zone ID
locals {
  route53_zone_id = var.create_route53_zone ? aws_route53_zone.main[0].zone_id : data.aws_route53_zone.main[0].zone_id
}

# ============================================================================
# CERTIFICAT ACM (SSL)
# ============================================================================

resource "aws_acm_certificate" "main" {
  count = var.environment == "prod" ? 1 : 0

  count = var.environment == "prod" ? 1 : 0

  domain_name       = var.domain_name
  validation_method = "DNS"

  subject_alternative_names = [
    "*.${var.domain_name}"
  ]

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(
    var.tags,
    {
      Name = var.domain_name
    }
  )
}

# ============================================================================
# VALIDATION DU CERTIFICAT via DNS
# ============================================================================

resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.main.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = local.route53_zone_id
}

resource "aws_acm_certificate_validation" "main" {
  count = var.environment == "prod" ? 1 : 0

  count = var.environment == "prod" ? 1 : 0

  certificate_arn         = aws_acm_certificate.main.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

# ============================================================================
# RECORD A - API (pointe vers l'ALB)
# ============================================================================

resource "aws_route53_record" "api" {
  depends_on = [aws_lb.main]

  zone_id = local.route53_zone_id
  name    = "api.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = true
  }
}

# ============================================================================
# RECORD A - APP/FRONTEND (pointe vers l'ALB)
# ============================================================================

resource "aws_route53_record" "app" {
  depends_on = [aws_lb.main]

  zone_id = local.route53_zone_id
  name    = "app.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = true
  }
}

# ============================================================================
# RECORD A - ROOT (optionnel, pointe vers l'ALB)
# ============================================================================

resource "aws_route53_record" "root" {
  depends_on = [aws_lb.main]

  zone_id = local.route53_zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = true
  }
}