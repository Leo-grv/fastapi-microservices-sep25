# ============================================================================
# EKS CLUSTER
# ============================================================================

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name    = "${substr(var.project_name, 0, 10)}-${var.environment}"
  cluster_version = var.eks_cluster_version

  vpc_id     = aws_vpc.main.id
  subnet_ids = aws_subnet.private_eks[*].id

  # Cluster endpoint access
  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true

  # Cluster security group
  cluster_security_group_id = aws_security_group.eks_cluster.id

  # OIDC Provider pour IAM roles for service accounts
  enable_irsa = true

  # Managed node groups
  eks_managed_node_groups = {
    main = {
      name = "main-ng"

      instance_types = var.eks_node_instance_types
      capacity_type  = "ON_DEMAND"

      min_size     = var.eks_node_min_size
      max_size     = var.eks_node_max_size
      desired_size = var.eks_node_desired_size

      # Use custom security group
      vpc_security_group_ids = [aws_security_group.eks_nodes.id]

      # IAM role
      iam_role_arn = aws_iam_role.eks_nodes.arn

      # Disk configuration
      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = 50
            volume_type           = "gp3"
            delete_on_termination = true
          }
        }
      }

      # Tags
      tags = merge(
        var.tags,
        {
          Name = "${var.project_name}-${var.environment}-node"
        }
      )
    }
  }

  # Cluster addons
  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
  }

  # Tags
  tags = merge(
    var.tags,
    {
      Environment = var.environment
    }
  )
}

# Installer External Secrets Operator via Helm
resource "helm_release" "external_secrets" {
  depends_on = [module.eks]

  name       = "external-secrets"
  repository = "https://charts.external-secrets.io"
  chart      = "external-secrets"
  namespace  = "external-secrets-system"
  create_namespace = true

  version = "0.9.9"
}

# ============================================================================
# KUBECONFIG
# ============================================================================

resource "null_resource" "kubeconfig" {
  depends_on = [module.eks]

  provisioner "local-exec" {
    command = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
  }
}

# ============================================================================
# CONFIGMAP AWS-AUTH (pour que les nodes puissent rejoindre le cluster)
# ============================================================================

resource "kubernetes_config_map_v1_data" "aws_auth" {
  depends_on = [module.eks]

  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = yamlencode([
      {
        rolearn  = aws_iam_role.eks_nodes.arn
        username = "system:node:{{EC2PrivateDNSName}}"
        groups = [
          "system:bootstrappers",
          "system:nodes"
        ]
      }
    ])
  }

  force = true
}

# ============================================================================
# FIX AWS-AUTH CONFIGMAP
# ============================================================================

resource "null_resource" "update_aws_auth" {
  depends_on = [module.eks]

  provisioner "local-exec" {
    command = <<-EOT
      sleep 30
      aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}
      
      kubectl patch configmap aws-auth -n kube-system --type merge -p '{
        "data": {
          "mapRoles": "- rolearn: ${aws_iam_role.eks_nodes.arn}\n  username: system:node:{{EC2PrivateDNSName}}\n  groups:\n    - system:bootstrappers\n    - system:nodes\n"
        }
      }'
    EOT
  }

  triggers = {
    cluster_name = module.eks.cluster_name
    node_role    = aws_iam_role.eks_nodes.arn
  }
}