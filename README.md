
```markdown
# Green City Project

![Terraform](https://img.shields.io/badge/infrastructure-Terraform-blue)
![Ansible](https://img.shields.io/badge/deployment-Ansible-orange)
![AWS](https://img.shields.io/badge/cloud-AWS-yellow)
![Docker](https://img.shields.io/badge/container-Docker-blue)
![ECR](https://img.shields.io/badge/registry-ECR-green)
![Vault](https://img.shields.io/badge/secrets-HashiCorp_Vault-purple)

A fully automated infrastructure and deployment pipeline for the **Green City** application, built on AWS with Terraform, Ansible, Docker, and ECR. Designed for **security, reproducibility, and CI/CD readiness**.

## 🏗️ Architecture Overview

- **Frontend**: Angular application served via Nginx in Docker.
- **Backend**: Java Spring Boot microservices:
  - `backcore` – Main business logic
  - `backuser` – User management
- **Database**: PostgreSQL hosted on AWS RDS (private subnet).
- **Infrastructure**: AWS VPC with public/private subnets, EC2 instances, security groups, and Internet Gateway.
- **Container Registry**: AWS ECR for storing Docker images.
- **Deployment**: Ansible automates configuration and deployment.
- **Secrets Management**: HashiCorp Vault for secure storage of credentials.

## 🔧 Technologies Used

| Tool | Purpose |
|------|--------|
| **Terraform** | Provisioning AWS infrastructure (VPC, EC2, RDS, etc.) |
| **Ansible** | Configuration management and deployment |
| **AWS** | Cloud infrastructure (EC2, RDS, ECR, VPC) |
| **Docker & Docker Compose** | Containerization of services |
| **ECR** | Private container registry |
| **HashiCorp Vault** | Secure storage of secrets (AWS keys, DB passwords, API keys) |
| **GitHub Actions** | CI/CD pipeline (build, push, deploy) |

## 🚀 Key Features

✅ **Infrastructure as Code (IaC)**  
All AWS resources are defined in Terraform and can be recreated at any time.

✅ **Dynamic Inventory**  
Ansible automatically discovers EC2 instances by tags and generates `inventory.ini` via `generate-inventory.sh`.

✅ **Immutable Image Tags**  
Images are tagged with Git commit SHA (e.g., `a1b2c3d`) — **not** `latest`. This enables:
- Full auditability
- Easy rollback
- Idempotent deployments

✅ **Secure Secrets Management**  
All sensitive data (AWS keys, DB passwords, OAuth credentials) are stored in **HashiCorp Vault**, never in code.

✅ **Automated Deployment**  
Ansible roles handle:
- Docker installation
- ECR login
- Image pull
- `config.js` generation
- `docker-compose up`

✅ **Separation of Concerns**
- `frontend` EC2 → runs only frontend
- `backend` EC2 → runs `backcore` and `backuser`
- RDS → isolated in private subnet

## 📂 Project Structure

```
.
├── terraform/               # AWS infrastructure
├── ansible/
│   ├── playbooks/
│   │   ├── discover-images.yml  # Get latest ECR tags
│   │   └── deploy.yml           # Deploy to EC2
│   ├── roles/
│   │   ├── green-city-frontend  # Frontend deployment
│   │   └── green-city-backend   # Backend deployment
│   ├── templates/
│   │   ├── config.js.j2         # Jinja2 template for frontend config
│   │   └── docker-compose.yml.j2
│   ├── generate-inventory.sh    # Generate inventory.ini from AWS
│   └── deploy.yml
└── .gitignore                 # inventory.ini, ecr_tags.json, keys ignored
```

## 🛠️ Deployment Workflow

1. **Apply Terraform**  
   ```bash
   terraform apply
   ```

2. **Generate Inventory**  
   ```bash
   ./generate-inventory.sh
   ```

3. **Get Latest Image Tags from ECR**  
   ```bash
   ansible-playbook -i inventory.ini playbooks/discover-images.yml
   ```

4. **Deploy Services**  
   ```bash
   ansible-playbook -i inventory.ini playbooks/deploy.yml
   ```

## 🔐 Security

- All EC2 instances are in a VPC.
- RDS is in a **private subnet** — not publicly accessible.
- SSH access only via key pair.
- Secrets stored in **HashiCorp Vault**, accessed via IAM and environment variables.
- No hardcoded credentials in code.

## 🔄 CI/CD Ready

This setup is designed for integration with **GitHub Actions**:
- On `git push`, GitHub Actions:
  - Builds Docker images
  - Tags with Git SHA
  - Pushes to ECR
  - Triggers Ansible deployment
- Full audit trail: you can always see which commit is running.

## 📊 Accessing the Application

After deployment:
- **Frontend**: `http://<frontend-ec2-public-ip>:4200`
- **Backcore API**: `http://<backend-ec2-public-ip>:8080/swagger-ui.html`
- **Backuser API**: `http://<backend-ec2-public-ip>:8060/swagger-ui.html`

## 📝 Notes

- `config.js` is generated dynamically with correct backend URLs.
- `docker-compose.yml` is templated and deployed via Ansible.
- The system is **fully reproducible** — destroy and rebuild anytime.

---

