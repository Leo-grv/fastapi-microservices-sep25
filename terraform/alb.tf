# ============================================================================
# APPLICATION LOAD BALANCER
# ============================================================================

resource "aws_lb" "main" {
  name               = "${var.project_name}-${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id

  enable_deletion_protection       = var.environment == "prod" ? true : false
  enable_http2                     = true
  enable_cross_zone_load_balancing = true

  access_logs {
    bucket  = aws_s3_bucket.alb_logs.bucket
    enabled = true
  }

  depends_on = [aws_s3_bucket_policy.alb_logs]

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-alb"
    }
  )
}

# ============================================================================
# TARGET GROUP - TRAEFIK
# ============================================================================

resource "aws_lb_target_group" "traefik" {
  name     = "${var.project_name}-${var.environment}-traefik"
  port     = 30080  # NodePort de Traefik (sera configuré dans K8s)
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/ping"  # Endpoint de health check de Traefik
    protocol            = "HTTP"
    matcher             = "200"
  }

  deregistration_delay = 30

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-traefik-tg"
    }
  )
}

# ============================================================================
# LISTENER HTTP (redirige vers HTTPS)
# ============================================================================

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  tags = var.tags
}

# ============================================================================
# LISTENER HTTPS
# ============================================================================

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = aws_acm_certificate.main.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.traefik.arn
  }

  depends_on = [aws_acm_certificate_validation.main]

  tags = var.tags
}

# ============================================================================
# LISTENER RULES - API
# ============================================================================

resource "aws_lb_listener_rule" "api" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.traefik.arn
  }

  condition {
    host_header {
      values = ["api.${var.domain_name}"]
    }
  }

  tags = var.tags
}

# ============================================================================
# LISTENER RULES - APP/FRONTEND
# ============================================================================

resource "aws_lb_listener_rule" "app" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 200

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.traefik.arn
  }

  condition {
    host_header {
      values = ["app.${var.domain_name}"]
    }
  }

  tags = var.tags
}

# ============================================================================
# AUTO SCALING TARGET ATTACHMENT
# Attache automatiquement les nodes EKS au target group
# ============================================================================

resource "aws_autoscaling_attachment" "traefik" {
  autoscaling_group_name = module.eks.eks_managed_node_groups["main"].node_group_autoscaling_group_names[0]
  lb_target_group_arn    = aws_lb_target_group.traefik.arn
}