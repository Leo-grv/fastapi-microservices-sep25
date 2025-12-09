# ============================================================================
# APPLICATION LOAD BALANCER
# ============================================================================

resource "aws_lb" "main" {
  name               = "${substr(var.project_name, 0, 15)}-${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id

  enable_deletion_protection       = var.environment == "prod" ? true : false
  enable_http2                     = true
  enable_cross_zone_load_balancing = true

  # Logs désactivés pour dev
  # access_logs {
  #   bucket  = aws_s3_bucket.alb_logs.bucket
  #   enabled = true
  # }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-alb"
    }
  )
}

# ============================================================================
# TARGET GROUP pour Traefik
# ============================================================================

resource "aws_lb_target_group" "traefik" {
  name     = "${substr(var.project_name, 0, 15)}-${var.environment}-trf"
  port     = 30080
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/ping"
    protocol            = "HTTP"
    matcher             = "200,404"
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
# LISTENER HTTP (Port 80)
# ============================================================================

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.traefik.arn
  }
}

# ============================================================================
# LISTENER HTTPS (Port 443) - Seulement pour PROD
# ============================================================================

#resource "aws_lb_listener" "https" {
#  count = var.environment == "prod" ? 1 : 0

#  load_balancer_arn = aws_lb.main.arn
#  port              = "443"
#"  protocol          = "HTTPS"
#  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
#  certificate_arn   = aws_acm_certificate_validation.main[0].certificate_arn

#  default_action {
#    type             = "forward"
#    target_group_arn = aws_lb_target_group.traefik.arn
#  }
#}

# ============================================================================
# ATTACHMENT du Target Group aux instances EKS
# ============================================================================

resource "aws_autoscaling_attachment" "eks_nodes" {
  autoscaling_group_name = module.eks.eks_managed_node_groups["main"].node_group_autoscaling_group_names[0]
  lb_target_group_arn    = aws_lb_target_group.traefik.arn
}
