# 🏗️ Architecture - FastAPI Microservices Platform

## 📊 Vue d'ensemble

Plateforme de microservices FastAPI déployable sur **k3s (local)** ou **AWS EKS (production)**.

```
┌─────────────────────────────────────────────────────────────────┐
│                         CLIENTS                                  │
│                    (Browser / Mobile)                            │
└────────────────┬────────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────────┐
│                    APPLICATION LOAD BALANCER                     │
│              (AWS ALB ou Traefik sur k3s)                       │
│                   Port 80 (HTTP) / 443 (HTTPS)                  │
└────────────┬───────────────────────────┬────────────────────────┘
             │                           │
             ▼                           ▼
    ┌────────────────┐          ┌────────────────┐
    │   FRONTEND     │          │   API GATEWAY  │
    │   (Next.js)    │          │   (Traefik)    │
    │   Port 3000    │          │                │
    └────────────────┘          └───┬────────────┘
                                    │
                    ┌───────────────┼───────────────┐
                    ▼               ▼               ▼
            ┌──────────────┐ ┌──────────────┐ ┌──────────────┐
            │ AUTH SERVICE │ │USERS SERVICE │ │ITEMS SERVICE │
            │  (FastAPI)   │ │  (FastAPI)   │ │  (FastAPI)   │
            │  Port 8000   │ │  Port 8000   │ │  Port 8000   │
            └──────┬───────┘ └──────┬───────┘ └──────┬───────┘
                   │                │                │
                   └────────────────┴────────────────┘
                                    │
                                    ▼
                        ┌───────────────────────┐
                        │   POSTGRESQL          │
                        │   (RDS ou Pod)        │
                        │   Port 5432           │
                        └───────────────────────┘
```

---

## 🎯 Stack Technique

### **Backend**
- **Framework** : FastAPI 0.115+
- **ORM** : SQLModel (SQLAlchemy 2.0)
- **Auth** : JWT avec bcrypt
- **Database** : PostgreSQL 17

### **Frontend**
- **Framework** : Next.js 14 (Pages Router)
- **UI** : React + Tailwind CSS
- **HTTP Client** : Axios
- **Auth** : JWT stored in localStorage

### **Infrastructure**
- **Container** : Docker
- **Orchestration** : Kubernetes (k3s local, EKS production)
- **IaC** : Terraform
- **Deployment** : Helm Charts
- **CI/CD** : GitHub Actions (à venir)

### **AWS Services (Production)**
- **Compute** : EKS (Elastic Kubernetes Service)
- **Database** : RDS PostgreSQL Multi-AZ
- **Load Balancer** : Application Load Balancer (ALB)
- **Secrets** : AWS Secrets Manager + External Secrets Operator
- **Storage** : S3 (logs, backups)
- **Networking** : VPC with public/private subnets

---

## 🔐 Sécurité

### **Authentication Flow**
```
1. User → POST /auth/api/v1/login/access-token
2. Auth Service → Verify credentials in DB
3. Auth Service → Generate JWT token
4. User → Store token in localStorage
5. User → Send token in Authorization: Bearer <token>
6. Services → Verify JWT + check user permissions
```

### **Secrets Management**

**Local (k3s):**
- Secrets stockés dans Kubernetes Secrets
- ConfigMap pour configuration non-sensible

**AWS (EKS):**
- Secrets stockés dans AWS Secrets Manager
- External Secrets Operator pour synchronisation
- IAM Roles for Service Accounts (IRSA)

---

## 🌐 Networking

### **Local (k3s)**
```
http://IP:30080/          → Frontend
http://IP:30081/api/v1    → Auth Service
http://IP:30082/api/v1    → Users Service
http://IP:30083/api/v1    → Items Service
```

### **AWS (EKS)**
```
https://app.votredomaine.com/       → Frontend
https://api.votredomaine.com/auth   → Auth Service
https://api.votredomaine.com/users  → Users Service
https://api.votredomaine.com/items  → Items Service
```

**Routing (Traefik Ingress):**
```
ALB (Port 80/443)
  ↓
Traefik (NodePort 30080)
  ↓
  ├─ /auth/*  → auth-service:80
  ├─ /users/* → users-service:80
  ├─ /items/* → items-service:80
  └─ /*       → frontend-service:80
```

---

## 📦 Microservices

### **1. Auth Service**
**Responsabilité** : Authentication & JWT generation

**Endpoints** :
- `POST /api/v1/login/access-token` - Login
- `GET /api/v1/login/test-token` - Verify token
- `GET /health` - Health check

**Database Tables** : `user`

---

### **2. Users Service**
**Responsabilité** : User management (CRUD)

**Endpoints** :
- `GET /api/v1/users/` - List users (superuser only)
- `GET /api/v1/users/me` - Get current user
- `PUT /api/v1/users/me` - Update profile
- `GET /api/v1/users/{id}` - Get user by ID
- `DELETE /api/v1/users/{id}` - Delete user (superuser)

**Database Tables** : `user`

---

### **3. Items Service**
**Responsabilité** : Item management (CRUD)

**Endpoints** :
- `GET /api/v1/items/` - List items
- `POST /api/v1/items/` - Create item
- `GET /api/v1/items/{id}` - Get item
- `PUT /api/v1/items/{id}` - Update item
- `DELETE /api/v1/items/{id}` - Delete item

**Database Tables** : `item`

---

### **4. Frontend**
**Responsabilité** : User interface

**Pages** :
- `/` - Login page
- `/dashboard` - User management
- `/items` - Items management
- `/admin` - Admin panel (superuser only)

---

## 🗄️ Database Schema

### **Table: user**
```sql
CREATE TABLE "user" (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    hashed_password VARCHAR(255) NOT NULL,
    full_name VARCHAR(255),
    is_active BOOLEAN DEFAULT true,
    is_superuser BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### **Table: item**
```sql
CREATE TABLE item (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    owner_id UUID REFERENCES "user"(id) ON DELETE CASCADE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

---

## 🔄 Environments

### **Dev (k3s local)**
- **VMs** : 1 node (2 vCPU, 4GB RAM)
- **Database** : PostgreSQL pod
- **Ingress** : Traefik (direct)
- **SSL** : Non (HTTP only)
- **Cost** : ~10$/mois

### **Production (AWS EKS)**
- **Compute** : 2-3 nodes t3.large
- **Database** : RDS PostgreSQL Multi-AZ
- **Ingress** : ALB → Traefik
- **SSL** : ACM Certificate (auto-renewed)
- **DNS** : Route53
- **Cost** : ~250-300$/mois

---

## 📊 Monitoring & Observability

### **Logs**
- **Local** : `kubectl logs`
- **AWS** : CloudWatch Logs

### **Metrics** (à venir)
- Prometheus + Grafana
- Custom dashboards

### **Alerting** (à venir)
- CloudWatch Alarms
- PagerDuty integration

---

## 🚀 Deployment

### **Local (k3s)**
```bash
helm upgrade --install platform ./helm/platform \
  -f ./overlays/dev/values.yaml \
  -n dev --create-namespace
```

### **AWS (EKS)**
```bash
# 1. Deploy infrastructure
cd terraform/
terraform apply

# 2. Configure kubectl
aws eks update-kubeconfig --region eu-west-3 --name microservi-dev

# 3. Deploy application
cd ../
helm upgrade --install platform ./helm/platform \
  -f ./overlays/aws/values.yaml \
  -n dev --create-namespace
```

---

## 🔧 Maintenance

### **Backup**
- **Local** : Manual PostgreSQL dumps
- **AWS** : RDS automated backups (7 days retention)

### **Updates**
- Rolling updates via Helm
- Zero-downtime deployments

### **Scaling**
- **Local** : Manual pod scaling
- **AWS** : Cluster Autoscaler + HPA

---

## 📚 Documentation

- [README.md](./README.md) - Getting started
- [AWS_MIGRATION.md](./AWS_MIGRATION.md) - Migration guide k3s → EKS
- [API Documentation](http://localhost:30081/docs) - Swagger UI (local)

---

**Last updated** : December 2024
