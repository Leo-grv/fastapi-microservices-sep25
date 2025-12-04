# 🚀 Microservices Platform - FastAPI sur AWS EKS

[![AWS](https://img.shields.io/badge/AWS-EKS-orange?logo=amazon-aws)](https://aws.amazon.com/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-1.28-blue?logo=kubernetes)](https://kubernetes.io/)
[![Terraform](https://img.shields.io/badge/Terraform-Infrastructure-purple?logo=terraform)](https://terraform.io/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15-blue?logo=postgresql)](https://postgresql.org/)

## 📋 Vue d'ensemble

Plateforme de microservices moderne déployée sur AWS avec Kubernetes (EKS), incluant :
- **Architecture microservices** : Services Auth, Users, Items, Frontend
- **Infrastructure as Code** : 100% géré avec Terraform
- **Haute disponibilité** : Multi-AZ sur 2 zones de disponibilité (eu-west-3)
- **Sécurité** : Subnets privés, Security Groups, encryption at-rest
- **Scalabilité** : Auto-scaling EKS (2-3 nodes), RDS Multi-AZ en PROD
- **CI/CD Ready** : Images Docker sur Docker Hub

---

## 🏗️ Architecture

```
Internet (HTTPS)
    │
    ├─── Route53 DNS (leotest.abrdns.com)
    │    ├─── api.leotest.abrdns.com → ALB
    │    ├─── app.leotest.abrdns.com → ALB
    │    └─── leotest.abrdns.com → ALB (root)
    │
    ▼
Application Load Balancer (Port 80/443)
    │
    ├─── Target Group (Traefik NodePort 30080)
    │
    ▼
VPC 10.0.0.0/16 - Multi-AZ (eu-west-3a, eu-west-3b)
    │
    ├─── Public Subnets (2 AZ)
    │    ├─── 10.0.1.0/24  (AZ-1) + NAT Gateway 1
    │    └─── 10.0.10.0/24 (AZ-2) + NAT Gateway 2
    │
    ├─── Private Subnets EKS (2 AZ)
    │    ├─── 10.0.2.0/24  (AZ-1) - EKS Worker Nodes
    │    └─── 10.0.20.0/24 (AZ-2) - EKS Worker Nodes
    │         │
    │         └─── EKS Cluster 1.28
    │              ├─── Traefik Ingress Controller (NodePort 30080)
    │              ├─── Auth Service (FastAPI - Port 8000)
    │              ├─── Users Service (FastAPI - Port 8000)
    │              ├─── Items Service (FastAPI - Port 8000)
    │              └─── Frontend (React - Port 3000)
    │
    └─── Private Subnets RDS (2 AZ)
         ├─── 10.0.3.0/24  (AZ-1) - RDS Primary
         └─── 10.0.30.0/24 (AZ-2) - RDS Standby (PROD only)
              │
              └─── PostgreSQL 15 (db.t3.small)
                   ├─── Database: microservices_dev
                   ├─── Port: 5432
                   └─── Storage: 20GB GP3 (encrypted)
```

---

## 🎯 Composants

### 🔐 **Auth Service**
- **Rôle** : Authentification JWT, gestion des utilisateurs
- **Tech** : FastAPI + SQLAlchemy + PostgreSQL
- **Endpoints** :
  - `POST /api/v1/login/access-token` - Login
  - `POST /api/v1/users/` - Register
  - `GET /api/v1/auth/verify` - Verify token (Traefik ForwardAuth)
- **Image** : `leogrv22/auth:dev`
- **Port** : 8000

### 👥 **Users Service**
- **Rôle** : CRUD utilisateurs, profils
- **Tech** : FastAPI + SQLAlchemy
- **Endpoints** :
  - `GET /api/v1/users/` - Liste des users
  - `GET /api/v1/users/{id}` - User par ID
  - `PUT /api/v1/users/{id}` - Update user
  - `DELETE /api/v1/users/{id}` - Delete user
- **Image** : `leogrv22/users:dev`
- **Port** : 8000

### 📦 **Items Service**
- **Rôle** : Gestion des items/ressources
- **Tech** : FastAPI + SQLAlchemy
- **Endpoints** :
  - `GET /api/v1/items/` - Liste des items
  - `POST /api/v1/items/` - Create item
  - `GET /api/v1/items/{id}` - Item par ID
  - `PUT /api/v1/items/{id}` - Update item
  - `DELETE /api/v1/items/{id}` - Delete item
- **Image** : `leogrv22/items:dev`
- **Port** : 8000

### 🌐 **Frontend**
- **Rôle** : Interface utilisateur web
- **Tech** : React.js / Next.js
- **Features** : Dashboard, Login, User Management
- **Image** : `leogrv22/frontend:dev`
- **Port** : 3000

### 🔀 **Traefik Ingress**
- **Rôle** : Reverse proxy, routing, SSL termination
- **Config** : NodePort 30080/30443
- **Features** : Path-based routing, middleware, ForwardAuth

### 🗄️ **PostgreSQL RDS**
- **Version** : 15.4
- **Instance** : db.t3.small (2 vCPU, 2 GB RAM)
- **Storage** : 20 GB GP3 (encrypted)
- **Backup** : 1 day retention (DEV), 7 days (PROD)
- **Multi-AZ** : Disabled (DEV), Enabled (PROD)

---

## 🛠️ Prérequis

### Outils nécessaires

```bash
# AWS CLI (>= 2.0)
aws --version

# Terraform (>= 1.0)
terraform version

# kubectl (>= 1.28)
kubectl version --client

# Helm (>= 3.0)
helm version

# Docker (>= 20.10)
docker --version
```

### Configuration AWS

```bash
# Configurer AWS CLI
aws configure
# AWS Access Key ID: AKIAXXXXX
# AWS Secret Access Key: xxxxxx
# Default region: eu-west-3
# Default output format: json

# Vérifier l'accès
aws sts get-caller-identity
```

---

## 🚀 Déploiement

### 1️⃣ Cloner le projet

```bash
git clone https://github.com/your-org/microservices-platform.git
cd microservices-platform
```

### 2️⃣ Structure du projet

```
microservices-platform/
├── terraform/                  # Infrastructure as Code
│   ├── main.tf                # Configuration principale
│   ├── vpc.tf                 # VPC, Subnets, NAT, IGW
│   ├── security-groups.tf     # Security Groups
│   ├── iam.tf                 # IAM Roles et Policies
│   ├── eks.tf                 # Cluster EKS
│   ├── rds.tf                 # PostgreSQL RDS
│   ├── alb.tf                 # Application Load Balancer
│   ├── route53.tf             # DNS et SSL Certificate
│   ├── s3.tf                  # S3 Buckets
│   ├── outputs.tf             # Outputs Terraform
│   ├── variables.tf           # Variables definition
│   ├── terraform.tfvars.dev   # Variables DEV
│   └── terraform.tfvars.prod  # Variables PROD
│
├── Microservices/             # Code des microservices
│   ├── auth/                  # Service d'authentification
│   │   ├── app/
│   │   ├── Dockerfile
│   │   └── requirements.txt
│   ├── users/                 # Service utilisateurs
│   ├── items/                 # Service items
│   └── frontend/              # Frontend React
│
├── helm/                      # Charts Helm
│   ├── platform/              # Chart umbrella
│   │   ├── Chart.yaml
│   │   ├── values.yaml
│   │   └── templates/
│   ├── auth/                  # Chart Auth
│   ├── users/                 # Chart Users
│   └── items/                 # Chart Items
│
└── overlays/                  # Configurations par environnement
    ├── dev/
    │   └── values.yaml
    ├── staging/
    │   └── values.yaml
    └── prod/
        └── values.yaml
```

### 3️⃣ Déployer l'infrastructure Terraform

```bash
cd terraform/

# Copier le fichier de variables pour DEV
cp terraform.tfvars.dev terraform.tfvars

# ⚠️ IMPORTANT : Éditer terraform.tfvars et changer les secrets
nano terraform.tfvars
```

**Variables à modifier OBLIGATOIREMENT** :
```hcl
# Mot de passe RDS (minimum 16 caractères)
rds_master_password = "VotreSuperMotDePasseSecurise123!"

# Secret key pour JWT (minimum 32 caractères)
app_secret_key = "votre-secret-key-tres-longue-et-aleatoire-123456789"
```

```bash
# Initialiser Terraform
terraform init

# Planifier (vérifier ce qui sera créé)
terraform plan

# Déployer (durée : 15-20 minutes)
terraform apply
# Confirmer avec : yes
```

### 4️⃣ Configurer kubectl

```bash
# Récupérer la commande depuis les outputs
terraform output configure_kubectl

# Exécuter la commande
aws eks update-kubeconfig --region eu-west-3 --name microser-dev

# Vérifier les nodes
kubectl get nodes
```

### 5️⃣ Déployer Traefik

```bash
# Ajouter le repo Helm
helm repo add traefik https://traefik.github.io/charts
helm repo update

# Créer le namespace
kubectl create namespace traefik

# Installer Traefik avec NodePort 30080
helm install traefik traefik/traefik \
  --namespace traefik \
  --set service.type=NodePort \
  --set ports.web.nodePort=30080 \
  --set ports.websecure.nodePort=30443

# Vérifier le déploiement
kubectl get svc -n traefik
kubectl get pods -n traefik
```

### 6️⃣ Déployer les microservices

```bash
# Retour à la racine du projet
cd ..

# Créer le namespace
kubectl create namespace dev

# Éditer les values avec les nouvelles URLs
nano overlays/dev/values.yaml

# Déployer avec Helm
cd helm/platform
helm dependency update

helm upgrade --install platform . \
  -f ../../overlays/dev/values.yaml \
  -n dev

# Vérifier le déploiement
kubectl get pods -n dev
kubectl get svc -n dev
kubectl get ingress -n dev
```

### 7️⃣ Initialiser la base de données

```bash
# Se connecter au pod Auth
kubectl exec -it -n dev $(kubectl get pod -n dev -l app=auth -o jsonpath='{.items[0].metadata.name}') -- bash

# Créer un utilisateur admin (depuis le pod)
python -c "
from app.core.security import get_password_hash
from app import crud, models
from app.core.config import settings
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

engine = create_engine(settings.DATABASE_URL)
SessionLocal = sessionmaker(bind=engine)
db = SessionLocal()

user = models.User(
    email='admin@test.com',
    hashed_password=get_password_hash('Test123!'),
    full_name='Admin User',
    is_superuser=True,
    is_active=True
)
db.add(user)
db.commit()
print('✅ Admin user created!')
"
```

### 8️⃣ Tester l'application

```bash
# Attendre que le DNS se propage (5-10 minutes)
# Récupérer l'URL de l'ALB
terraform output alb_dns_name

# Health check
curl http://api.leotest.abrdns.com/health

# Login
curl -X POST http://api.leotest.abrdns.com/auth/api/v1/login/access-token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=admin@test.com&password=Test123!"

# Frontend
curl http://app.leotest.abrdns.com
```

---

## 🔐 Sécurité

### Security Groups

| Composant | Ingress | Egress | Source |
|-----------|---------|--------|--------|
| **ALB** | 80, 443 | All | 0.0.0.0/0 |
| **EKS Nodes** | 30000-32767, 80, 443 | All | ALB SG |
| **RDS** | 5432 | All | EKS Nodes SG |

### Secrets Management

```bash
# Récupérer la DATABASE_URL depuis Kubernetes
kubectl get secret database-credentials -n default \
  -o jsonpath='{.data.DATABASE_URL}' | base64 -d

# Récupérer le mot de passe RDS
terraform output -raw rds_password
```

### IAM Roles

- **EKS Cluster Role** : Gestion du control plane
- **EKS Node Role** : Permissions des worker nodes
- **RDS Monitoring Role** : Enhanced monitoring

---

## 📊 Monitoring

### Logs CloudWatch

```bash
# Logs RDS
aws logs tail /aws/rds/instance/microservices-platform-dev-db/postgresql --follow

# Logs EKS
kubectl logs -n dev -l app=auth --tail=100 -f
```

### Métriques

```bash
# Nodes EKS
kubectl top nodes

# Pods
kubectl top pods -n dev

# Services
kubectl get svc -n dev -o wide
```

---

## 💰 Estimation des coûts

### Environnement DEV (sans Multi-AZ)

| Service | Configuration | Prix/mois |
|---------|--------------|-----------|
| EKS Control Plane | 1 cluster | ~$73 |
| EC2 (EKS Nodes) | 2x t3.medium | ~$60 |
| RDS PostgreSQL | db.t3.small | ~$30 |
| ALB | 1 ALB | ~$20 |
| NAT Gateway | 2x NAT | ~$65 |
| Route53 | 1 zone + queries | ~$2 |
| **Total** | | **~$250/mois** |

### Environnement PROD (avec Multi-AZ)

| Service | Configuration | Prix/mois |
|---------|--------------|-----------|
| EKS Control Plane | 1 cluster | ~$73 |
| EC2 (EKS Nodes) | 3x t3.medium | ~$90 |
| RDS PostgreSQL | db.t3.small Multi-AZ | ~$60 |
| ALB | 1 ALB | ~$20 |
| NAT Gateway | 2x NAT | ~$65 |
| Route53 | 1 zone + queries | ~$2 |
| **Total** | | **~$310/mois** |

💡 **Économies possibles** :
- Utiliser Spot Instances pour EKS : -70% sur les nodes
- Réduire à 1 NAT Gateway (non-HA) : -$32/mois
- Arrêter l'environnement hors heures de travail

---

## 🔄 CI/CD

### Build et Push des images Docker

```bash
# Build toutes les images
docker-compose build

# Tag pour DEV
docker tag auth:latest leogrv22/auth:dev
docker tag users:latest leogrv22/users:dev
docker tag items:latest leogrv22/items:dev
docker tag frontend:latest leogrv22/frontend:dev

# Push vers Docker Hub
docker push leogrv22/auth:dev
docker push leogrv22/users:dev
docker push leogrv22/items:dev
docker push leogrv22/frontend:dev
```

### Rolling Update

```bash
# Update d'un service après push d'une nouvelle image
kubectl rollout restart deployment/auth -n dev

# Vérifier le rollout
kubectl rollout status deployment/auth -n dev

# Rollback si problème
kubectl rollout undo deployment/auth -n dev
```

---

## 🧹 Nettoyage

### Supprimer l'application

```bash
# Supprimer les ressources Kubernetes
helm uninstall platform -n dev
helm uninstall traefik -n traefik

kubectl delete namespace dev
kubectl delete namespace traefik
```

### Détruire l'infrastructure

```bash
cd terraform/

# ⚠️ ATTENTION : Ceci supprime TOUT !
terraform destroy
# Confirmer avec : yes
```

---

## 🐛 Troubleshooting

### Pods en CrashLoopBackOff

```bash
# Voir les logs du pod
kubectl logs -n dev <pod-name>

# Voir les events
kubectl get events -n dev --sort-by='.lastTimestamp' | tail -20

# Describe le pod
kubectl describe pod -n dev <pod-name>
```

### Nodes ne rejoignent pas le cluster

```bash
# Vérifier aws-auth configmap
kubectl get configmap aws-auth -n kube-system -o yaml

# Vérifier les logs du node
aws ssm start-session --target <instance-id>
```

### ALB ne route pas vers Traefik

```bash
# Vérifier le Target Group Health
aws elbv2 describe-target-health \
  --target-group-arn $(terraform output -raw target_group_arn)

# Vérifier que Traefik écoute sur NodePort 30080
kubectl get svc -n traefik traefik -o yaml | grep nodePort
```

### RDS Connection Failed

```bash
# Vérifier le Security Group
aws ec2 describe-security-groups \
  --group-ids $(terraform output -raw rds_security_group_id)

# Tester la connexion depuis un pod
kubectl run -it --rm psql-test --image=postgres:15 --restart=Never -n dev -- \
  psql -h <rds-endpoint> -U admin -d microservices_dev
```

---

## 📚 Documentation

- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Traefik Documentation](https://doc.traefik.io/traefik/)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [Helm Documentation](https://helm.sh/docs/)

---

## 👥 Équipe

- **Platform Team** : Infrastructure et DevOps
- **Backend Team** : Microservices FastAPI
- **Frontend Team** : Interface React

---

## 📝 Changelog

### Version 1.0.0 (2025-12)
- ✅ Déploiement initial sur AWS EKS
- ✅ Infrastructure Multi-AZ (2 zones)
- ✅ Microservices Auth, Users, Items, Frontend
- ✅ RDS PostgreSQL 15 avec backup automatique
- ✅ ALB + Route53 + SSL (PROD)
- ✅ Monitoring CloudWatch
- ✅ Auto-scaling EKS (2-3 nodes)

---

## 📄 Licence

MIT License - Copyright (c) 2025 Microservices Platform Team

---

## 🆘 Support

Pour toute question ou problème :
- 📧 Email : platform-team@example.com
- 💬 Slack : #platform-support
- 🐛 Issues : [GitHub Issues](https://github.com/your-org/microservices-platform/issues)

---

**🎉 Bon déploiement ! 🚀**
