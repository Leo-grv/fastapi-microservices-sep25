# 🚀 Migration de k3s vers AWS EKS

Ce guide détaille la procédure complète pour migrer votre application de **k3s (local)** vers **AWS EKS (production)**.

---

## 📋 Table des matières

- [Vue d'ensemble](#-vue-densemble)
- [Prérequis](#-prérequis)
- [Étape 1 : Préparation](#-étape-1--préparation)
- [Étape 2 : Infrastructure Terraform](#-étape-2--infrastructure-terraform)
- [Étape 3 : Configuration Kubernetes](#-étape-3--configuration-kubernetes)
- [Étape 4 : Déploiement Application](#-étape-4--déploiement-application)
- [Étape 5 : Vérification](#-étape-5--vérification)
- [Différences k3s vs EKS](#-différences-k3s-vs-eks)
- [Troubleshooting](#-troubleshooting)

---

## 🎯 Vue d'ensemble

### **Changements principaux**

| Composant | k3s (Local) | AWS EKS (Production) |
|-----------|-------------|----------------------|
| **Kubernetes** | k3s single node | EKS Multi-AZ Cluster |
| **Database** | PostgreSQL Pod | RDS PostgreSQL Multi-AZ |
| **Load Balancer** | Traefik (direct) | ALB → Traefik (NodePort) |
| **Secrets** | Kubernetes Secrets | AWS Secrets Manager + ESO |
| **SSL** | Aucun (HTTP) | ACM Certificate (HTTPS) |
| **DNS** | IP publique | Route53 |
| **Backup** | Manuel | Automatisé (RDS) |
| **Coût** | ~10$/mois | ~250-300$/mois |

---

## ✅ Prérequis

### **1. Outils installés**

```bash
# Vérifier les versions
aws --version          # AWS CLI 2.x
terraform --version    # Terraform 1.5+
kubectl version        # kubectl 1.28+
helm version           # Helm 3.12+
```

### **2. Credentials AWS configurées**

```bash
aws configure
# AWS Access Key ID: VOTRE_ACCESS_KEY
# AWS Secret Access Key: VOTRE_SECRET_KEY
# Default region name: eu-west-3
# Default output format: json

# Vérifier
aws sts get-caller-identity
```

### **3. Images Docker publiées**

Assurez-vous que vos images sont sur Docker Hub :

```bash
docker images | grep leogrv22
# leogrv22/auth:dev
# leogrv22/users:dev
# leogrv22/items:dev
# leogrv22/frontend:dev
```

---

## 📦 Étape 1 : Préparation

### **1.1 Créer le secret AWS Secrets Manager**

```bash
aws secretsmanager create-secret \
  --name microservices-platform-dev-secrets \
  --description "Application secrets for dev environment" \
  --secret-string '{
    "rds_master_password": "ChangeThisSecurePassword123!",
    "app_secret_key": "change-this-random-secret-key-32chars",
    "SECRET_KEY": "another-secret-for-jwt-signing"
  }' \
  --region eu-west-3
```

**⚠️ Important :** Changez les valeurs par défaut !

### **1.2 Vérifier le secret**

```bash
aws secretsmanager get-secret-value \
  --secret-id microservices-platform-dev-secrets \
  --region eu-west-3 \
  --query SecretString \
  --output text | jq .
```

### **1.3 Backup de la base de données locale (optionnel)**

Si vous avez des données à migrer :

```bash
# Depuis k3s
kubectl exec -n dev postgres-postgresql-0 -- \
  pg_dump -U postgres postgres > backup.sql

# Vous l'importerez plus tard dans RDS
```

---

## 🏗️ Étape 2 : Infrastructure Terraform

### **2.1 Vérifier les variables**

Éditez `terraform/variables.tf` et vérifiez :

```hcl
variable "aws_region" {
  default = "eu-west-3"  # ✅ Correct
}

variable "project_name" {
  default = "microservices-platform"
}

variable "environment" {
  default = "dev"
}

variable "rds_master_username" {
  default = "postgres"  # ✅ Pas "admin" (mot réservé)
}

variable "rds_engine_version" {
  default = "17.2"  # ✅ Version disponible
}
```

### **2.2 Initialiser Terraform**

```bash
cd terraform/

terraform init
```

### **2.3 Planifier le déploiement**

```bash
terraform plan
```

**Vérifiez que le plan va créer :**
- ✅ VPC avec 6 subnets (3 publics, 3 privés)
- ✅ EKS Cluster
- ✅ 2+ Node Groups
- ✅ RDS PostgreSQL
- ✅ ALB + Target Groups
- ✅ Security Groups
- ✅ IAM Roles

### **2.4 Déployer l'infrastructure**

```bash
terraform apply
```

**⏳ Durée : ~30-40 minutes**

```
Creating VPC...                          [████████] 2 min
Creating Security Groups...              [████████] 1 min
Creating IAM Roles...                    [████████] 1 min
Creating RDS PostgreSQL...               [████████] 10-15 min
Creating EKS Cluster...                  [████████] 10-15 min
Creating EKS Node Groups...              [████████] 5-10 min
Creating ALB...                          [████████] 3 min
Installing External Secrets Operator...  [████████] 2 min
Creating Kubernetes Secrets...           [████████] 1 min
```

### **2.5 Noter les outputs**

```bash
terraform output
```

**Outputs importants :**
- `eks_cluster_name` : microservi-dev
- `rds_endpoint` : microservices-platform-dev-db.XXXXX.rds.amazonaws.com
- `alb_dns_name` : microservices-p-dev-alb-XXXXX.elb.amazonaws.com
- `configure_kubectl` : Commande pour kubectl

---

## ⚙️ Étape 3 : Configuration Kubernetes

### **3.1 Configurer kubectl**

```bash
# Utiliser la commande depuis terraform output
aws eks update-kubeconfig --region eu-west-3 --name microservi-dev

# Vérifier la connexion
kubectl get nodes
```

**Expected output :**
```
NAME                                           STATUS   ROLES    AGE   VERSION
ip-10-0-1-123.eu-west-3.compute.internal      Ready    <none>   5m    v1.31.x
ip-10-0-2-234.eu-west-3.compute.internal      Ready    <none>   5m    v1.31.x
```

### **3.2 Vérifier External Secrets Operator**

```bash
kubectl get pods -n external-secrets-system
```

**Expected output :**
```
NAME                                                READY   STATUS    
external-secrets-xxx                                1/1     Running
external-secrets-cert-controller-xxx                1/1     Running
external-secrets-webhook-xxx                        1/1     Running
```

Si pas installé :

```bash
helm repo add external-secrets https://charts.external-secrets.io
helm repo update

helm install external-secrets external-secrets/external-secrets \
  -n external-secrets-system \
  --create-namespace
```

### **3.3 Créer le SecretStore**

Créez `k8s/secret-store.yaml` :

```yaml
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: aws-secrets-store
  namespace: dev
spec:
  provider:
    aws:
      service: SecretsManager
      region: eu-west-3
      auth:
        jwt:
          serviceAccountRef:
            name: default
```

Appliquez :

```bash
kubectl create namespace dev
kubectl apply -f k8s/secret-store.yaml
```

### **3.4 Créer l'ExternalSecret**

Créez `k8s/external-secret.yaml` :

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: database-credentials
  namespace: dev
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: aws-secrets-store
    kind: SecretStore
  target:
    name: database-credentials
    creationPolicy: Owner
  dataFrom:
    - extract:
        key: microservices-platform-dev-secrets
```

Appliquez :

```bash
kubectl apply -f k8s/external-secret.yaml
```

### **3.5 Vérifier le secret Kubernetes**

```bash
kubectl get externalsecret -n dev
kubectl get secret database-credentials -n dev -o yaml
```

---

## 🚢 Étape 4 : Déploiement Application

### **4.1 Créer les Helm values pour AWS**

Créez `overlays/aws/values.yaml` :

```yaml
global:
  useExternalSecrets: true
  imageRegistry: docker.io
  environment: dev
  
  # Base de données RDS (récupérer depuis terraform output)
  database:
    host: microservices-platform-dev-db.cvrhlcdjhuda.eu-west-3.rds.amazonaws.com
    port: "5432"
    name: microservices
    user: postgres

# Auth Service
auth:
  image:
    repository: leogrv22/auth
    tag: dev
    pullPolicy: Always
  
  service:
    type: ClusterIP  # Plus de NodePort, on passe par l'ALB
    port: 80
    targetPort: 8000
  
  ingress:
    enabled: false

# Users Service
users:
  image:
    repository: leogrv22/users
    tag: dev
    pullPolicy: Always
  
  service:
    type: ClusterIP
    port: 80
    targetPort: 8000
  
  ingress:
    enabled: false

# Items Service
items:
  image:
    repository: leogrv22/items
    tag: dev
    pullPolicy: Always
  
  service:
    type: ClusterIP
    port: 80
    targetPort: 8000
  
  ingress:
    enabled: false

# Frontend
frontend:
  image:
    repository: leogrv22/frontend
    tag: dev
    pullPolicy: Always
  
  service:
    type: ClusterIP
    port: 80
    targetPort: 3000
  
  env:
    # URL de l'ALB (ou domaine si configuré)
    NEXT_PUBLIC_API_BASE: "http://microservices-p-dev-alb-XXXXX.eu-west-3.elb.amazonaws.com"
  
  ingress:
    enabled: false

# Désactiver PostgreSQL (on utilise RDS)
postgresql:
  enabled: false
```

**⚠️ Remplacez :**
- `database.host` par l'output Terraform `rds_endpoint`
- `frontend.env.NEXT_PUBLIC_API_BASE` par l'output `alb_dns_name`

### **4.2 Modifier les deployments pour utiliser External Secrets**

Dans chaque subchart (`helm/auth/`, `helm/users/`, `helm/items/`), modifiez `templates/deployment.yaml` :

**Remplacez la section `envFrom` :**

```yaml
# Avant
envFrom:
  - secretRef:
      name: {{ include "auth.fullname" . }}-secret

# Après
envFrom:
  {{- if .Values.global.useExternalSecrets }}
  - secretRef:
      name: database-credentials  # Secret créé par External Secrets Operator
  {{- else }}
  - configMapRef:
      name: {{ include "auth.fullname" . }}-config
  - secretRef:
      name: {{ include "auth.fullname" . }}-secret
  {{- end }}
```

### **4.3 Update Helm dependencies**

```bash
cd helm/platform
helm dependency update
```

### **4.4 Déployer l'application**

```bash
helm upgrade --install platform . \
  -f ../../overlays/aws/values.yaml \
  -n dev \
  --create-namespace \
  --wait
```

### **4.5 Patcher les services en NodePort (pour ALB)**

Les services doivent être exposés en NodePort pour que l'ALB puisse les atteindre :

```bash
# Auth
kubectl patch svc platform-auth -n dev -p '{"spec":{"type":"NodePort","ports":[{"port":80,"targetPort":8000,"nodePort":30081}]}}'

# Users
kubectl patch svc platform-users -n dev -p '{"spec":{"type":"NodePort","ports":[{"port":80,"targetPort":8000,"nodePort":30082}]}}'

# Items
kubectl patch svc platform-items -n dev -p '{"spec":{"type":"NodePort","ports":[{"port":80,"targetPort":8000,"nodePort":30083}]}}'

# Frontend
kubectl patch svc platform-frontend -n dev -p '{"spec":{"type":"NodePort","ports":[{"port":80,"targetPort":3000,"nodePort":30080}]}}'
```

---

## ✅ Étape 5 : Vérification

### **5.1 Vérifier les pods**

```bash
kubectl get pods -n dev
```

**Tous les pods doivent être `Running` :**

```
NAME                                READY   STATUS    RESTARTS   AGE
platform-auth-xxx                   1/1     Running   0          2m
platform-users-xxx                  1/1     Running   0          2m
platform-items-xxx                  1/1     Running   0          2m
platform-frontend-xxx               1/1     Running   0          2m
```

### **5.2 Vérifier les services**

```bash
kubectl get svc -n dev
```

**Tous doivent être en NodePort :**

```
NAME                TYPE       CLUSTER-IP      PORT(S)
platform-auth       NodePort   10.43.x.x       80:30081/TCP
platform-users      NodePort   10.43.x.x       80:30082/TCP
platform-items      NodePort   10.43.x.x       80:30083/TCP
platform-frontend   NodePort   10.43.x.x       80:30080/TCP
```

### **5.3 Tester la connexion RDS**

```bash
# Depuis un pod
kubectl run psql-test --rm -it --image=postgres:17 -- \
  psql "$(kubectl get secret database-credentials -n dev -o jsonpath='{.data.DATABASE_URL}' | base64 -d)"

# Dans psql
\l  # Lister les databases
\dt # Lister les tables
\q  # Quitter
```

### **5.4 Créer l'utilisateur de test**

```bash
kubectl exec -it -n dev $(kubectl get pod -n dev -l app.kubernetes.io/name=auth -o jsonpath='{.items[0].metadata.name}') -- python3

# Dans Python
from app.core.security import get_password_hash
from app.models import User
from app.core.db import engine
from sqlmodel import Session

with Session(engine) as session:
    user = User(
        email="admin@test.com",
        hashed_password=get_password_hash("Test123!"),
        full_name="Admin User",
        is_active=True,
        is_superuser=True
    )
    session.add(user)
    session.commit()
    print("✅ User created!")
```

### **5.5 Tester l'API via l'ALB**

```bash
# Récupérer l'URL de l'ALB
ALB_URL=$(terraform output -raw alb_dns_name)

# Tester le frontend
curl http://$ALB_URL/

# Tester l'API auth
curl http://$ALB_URL:30081/docs

# Tester le login
curl -X POST "http://$ALB_URL:30081/api/v1/login/access-token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=admin@test.com&password=Test123!"
```

### **5.6 Accéder depuis le navigateur**

Ouvrez dans votre navigateur :

```
http://ALB_DNS_NAME:30080/
```

Connectez-vous avec :
- **Email :** admin@test.com
- **Password :** Test123!

---

## 🔄 Différences k3s vs EKS

### **Configuration Helm**

**k3s (`overlays/dev/values.yaml`) :**
```yaml
global:
  useExternalSecrets: false
  database:
    host: postgres-postgresql.dev.svc.cluster.local

auth:
  service:
    type: NodePort
    nodePort: 30081

postgresql:
  enabled: true  # Pod PostgreSQL
```

**EKS (`overlays/aws/values.yaml`) :**
```yaml
global:
  useExternalSecrets: true  # AWS Secrets Manager
  database:
    host: xxx.rds.amazonaws.com  # RDS

auth:
  service:
    type: ClusterIP  # Exposé via ALB

postgresql:
  enabled: false  # Utilise RDS
```

### **Secrets Management**

**k3s :**
- Secrets Kubernetes classiques
- Mot de passe en clair dans values.yaml

**EKS :**
- AWS Secrets Manager
- External Secrets Operator
- IAM Roles pour accès sécurisé

### **Networking**

**k3s :**
```
Internet → VM IP:30080 → Traefik → Services
```

**EKS :**
```
Internet → ALB:80 → NodePort 30080 → Traefik → Services
```

---

## 🐛 Troubleshooting

### **Problème : Pods en CrashLoopBackOff**

```bash
# Voir les logs
kubectl logs -n dev POD_NAME

# Souvent c'est un problème de connexion DB
kubectl describe pod -n dev POD_NAME
```

**Solutions :**
- Vérifier que le secret `database-credentials` existe
- Vérifier les Security Groups RDS (doit autoriser EKS nodes)
- Vérifier le RDS endpoint dans les values

### **Problème : ALB ne route pas vers les services**

```bash
# Vérifier le Target Group health
aws elbv2 describe-target-health \
  --target-group-arn $(aws elbv2 describe-target-groups \
    --names microservices-p-dev-trf \
    --query 'TargetGroups[0].TargetGroupArn' \
    --output text)
```

**Solutions :**
- Vérifier que les services sont en NodePort
- Vérifier les Security Groups (EKS nodes doivent accepter du ALB)
- Vérifier que les pods sont Running

### **Problème : External Secrets ne synchronise pas**

```bash
kubectl get externalsecret -n dev
kubectl describe externalsecret database-credentials -n dev
```

**Solutions :**
- Vérifier que le SecretStore existe
- Vérifier les IAM permissions des nodes
- Vérifier le nom du secret dans AWS Secrets Manager

### **Problème : RDS inaccessible**

```bash
# Tester la résolution DNS
kubectl run -it --rm debug --image=busybox -- nslookup microservices-platform-dev-db.xxx.rds.amazonaws.com

# Tester la connexion
kubectl run -it --rm psql --image=postgres:17 -- \
  psql -h RDS_ENDPOINT -U postgres -d microservices
```

**Solutions :**
- Vérifier le Security Group RDS
- Vérifier que RDS est dans les bons subnets
- Vérifier les credentials

---

## ✅ Checklist de migration

- [ ] Secret AWS Secrets Manager créé
- [ ] Infrastructure Terraform déployée (~40 min)
- [ ] kubectl configuré pour EKS
- [ ] External Secrets Operator vérifié
- [ ] SecretStore créé
- [ ] ExternalSecret créé
- [ ] Secret Kubernetes synchronisé
- [ ] Helm values AWS créés
- [ ] Deployments modifiés pour External Secrets
- [ ] Application déployée avec Helm
- [ ] Services patchés en NodePort
- [ ] Pods tous Running
- [ ] Connexion RDS testée
- [ ] Utilisateur test créé
- [ ] API testée via ALB
- [ ] Frontend accessible

---

## 🎉 Prochaines étapes

1. **Configurer un domaine** (Route53 + ACM Certificate)
2. **Activer HTTPS** (ALB Listener HTTPS)
3. **Setup monitoring** (CloudWatch, Prometheus/Grafana)
4. **Configurer CI/CD** (GitHub Actions → ECR → EKS)
5. **Backup automatisés** (RDS snapshots)
6. **Disaster Recovery plan**

---

**Migration terminée ! Votre application tourne maintenant sur AWS EKS ! 🚀**
