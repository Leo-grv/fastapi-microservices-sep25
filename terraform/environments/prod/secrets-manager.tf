# Référence au secret existant (créé manuellement)
data "aws_secretsmanager_secret" "app_secrets" {
  name = "microservices-platform-${var.environment}-secrets"
}

data "aws_secretsmanager_secret_version" "app_secrets" {
  secret_id = data.aws_secretsmanager_secret.app_secrets.id
}