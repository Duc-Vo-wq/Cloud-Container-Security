# Cloud Container Security Pipeline

A comprehensive DevSecOps project demonstrating secure containerized application deployment with CI/CD, vulnerability scanning, and runtime threat detection on AWS.

## 🎯 Project Overview

This project implements a production-ready container security pipeline featuring:

- **Secure Container Development**: Multi-stage Dockerfiles, non-root users, minimal attack surface
- **Automated CI/CD**: GitHub Actions with integrated security scanning
- **Vulnerability Management**: Trivy scanning with automated alerts
- **Infrastructure as Code**: Terraform-managed AWS infrastructure (VPC, ECR, ECS)
- **Runtime Security**: Falco-based threat detection and monitoring
- **Cloud-Native Architecture**: AWS ECS Fargate with Application Load Balancer

## 📋 Architecture

```
┌─────────────┐      ┌──────────────┐      ┌─────────────┐
│  Developer  │─────>│ GitHub Repo  │─────>│   GitHub    │
│             │      │              │      │   Actions   │
└─────────────┘      └──────────────┘      └──────┬──────┘
                                                   │
                                            ┌──────▼──────┐
                                            │   Security  │
                                            │   Scanning  │
                                            │   (Trivy)   │
                                            └──────┬──────┘
                                                   │
                                            ┌──────▼──────┐
                                            │  Container  │
                                            │   Signing   │
                                            │  (Cosign)   │
                                            └──────┬──────┘
                                                   │
                     ┌─────────────────────────────▼─────────────────────┐
                     │                    AWS ECR                         │
                     │            (Private Container Registry)            │
                     └─────────────────────────┬───────────────────────── ┘
                                               │
                     ┌─────────────────────────▼─────────────────────────┐
                     │                AWS ECS (Fargate)                   │
                     │  ┌──────────┐  ┌──────────┐  ┌──────────┐        │
                     │  │Container │  │Container │  │Container │        │
                     │  │  + Falco │  │  + Falco │  │  + Falco │        │
                     │  └────┬─────┘  └────┬─────┘  └────┬─────┘        │
                     └───────┼─────────────┼─────────────┼───────────────┘
                             │             │             │
                     ┌───────▼─────────────▼─────────────▼───────────────┐
                     │        Application Load Balancer (ALB)             │
                     └────────────────────────┬───────────────────────────┘
                                              │
                                              ▼
                                         [ Users ]

Monitoring & Logging:
┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│  CloudWatch  │    │    Falco     │    │  VPC Flow    │
│     Logs     │    │    Alerts    │    │     Logs     │
└──────────────┘    └──────────────┘    └──────────────┘
```

## 🚀 Quick Start

### Prerequisites

- AWS Account with appropriate permissions
- AWS CLI configured (`aws configure`)
- Docker Desktop installed
- Terraform >= 1.0
- Git
- Python 3.11+

### Installation

1. **Clone the repository**
```bash
git clone <your-repo-url>
cd cloud-container-security
```

2. **Configure AWS credentials**
```bash
aws configure
# Enter your AWS Access Key ID, Secret Key, and region
```

3. **Deploy infrastructure**
```bash
chmod +x scripts/deployment/deploy.sh
./scripts/deployment/deploy.sh deploy
```

4. **Wait for deployment** (5-10 minutes)
The script will:
- Initialize Terraform
- Create AWS infrastructure (VPC, ECR, ECS, ALB)
- Build and scan the container image
- Push to ECR
- Deploy to ECS
- Verify the deployment

5. **Access your application**
```bash
# URL will be displayed at the end of deployment
curl http://<your-alb-url>/health
```

## 📁 Project Structure

```
cloud-container-security/
├── app/
│   ├── app.py                 # Flask application
│   ├── requirements.txt       # Python dependencies
│   ├── Dockerfile            # Hardened multi-stage build
│   ├── .dockerignore
│   └── templates/
│       └── index.html
├── .github/
│   └── workflows/
│       └── security-pipeline.yml  # Complete CI/CD pipeline
├── terraform/
│   ├── main.tf               # Main infrastructure
│   ├── variables.tf
│   ├── outputs.tf
│   └── modules/
│       ├── vpc/              # VPC module
│       ├── ecr/              # ECR module
│       └── ecs/              # ECS module
├── security/
│   └── falco-rules/
│       ├── custom_rules.yaml # Custom Falco rules
│       └── falco.yaml        # Falco configuration
├── scripts/
│   ├── deployment/
│   │   └── deploy.sh         # Deployment automation
│   └── attacks/
│       ├── simulate_attacks.sh    # Container attack simulation
│       └── web_attacks.py         # Web attack simulation
├── docs/
│   ├── diagrams/             # Architecture diagrams
│   └── reports/              # Security reports
└── README.md
```

## 🔒 Security Features

### 1. Container Hardening
- ✅ Multi-stage builds for minimal image size
- ✅ Non-root user execution
- ✅ Read-only root filesystem
- ✅ Dropped Linux capabilities
- ✅ No secrets in images
- ✅ Minimal base images (Python slim)

### 2. Vulnerability Scanning
- ✅ Trivy scanning in CI/CD pipeline
- ✅ Blocks deployment on critical vulnerabilities
- ✅ SARIF reports to GitHub Security
- ✅ SBOM generation (CycloneDX)

### 3. Supply Chain Security
- ✅ Container image signing with Cosign
- ✅ Private ECR repository
- ✅ Image scanning on push
- ✅ Lifecycle policies for old images

### 4. Infrastructure Security
- ✅ Private subnets for containers
- ✅ Security groups with least privilege
- ✅ VPC Flow Logs enabled
- ✅ Encrypted ECR repositories (KMS)
- ✅ IAM roles with minimal permissions

### 5. Runtime Security
- ✅ Falco runtime threat detection
- ✅ Custom rules for container anomalies
- ✅ CloudWatch integration
- ✅ Real-time alerting

### 6. Network Security
- ✅ Application Load Balancer
- ✅ Security groups restricting traffic
- ✅ Private container networking
- ✅ NAT Gateway for outbound traffic

## 🔍 CI/CD Pipeline

The GitHub Actions pipeline includes:

1. **Security Scanning**
   - Code scanning with Bandit
   - Dependency vulnerability scanning

2. **Build and Scan**
   - Docker image build
   - Trivy vulnerability scanning
   - Fail on critical vulnerabilities
   - Generate SARIF reports

3. **Sign and Push**
   - Sign images with Cosign
   - Push to private ECR
   - Generate SBOM

4. **Deploy**
   - Update ECS task definition
   - Deploy to ECS service
   - Wait for service stability
   - Verify deployment

## 🛡️ Runtime Monitoring with Falco

Falco monitors containers for suspicious activity:

- Unauthorized process execution
- File system modifications
- Network anomalies
- Privilege escalation attempts
- Package installation in running containers
- Sensitive file access
- Shell spawning
- Cryptocurrency mining

View Falco alerts:
```bash
aws logs tail /ecs/production/flask-app --follow
```

## 🧪 Testing Security

### 1. Test Local Container
```bash
cd app
docker build -t flask-app:test .
docker run -p 5000:5000 flask-app:test

# In another terminal
curl http://localhost:5000/health
```

### 2. Scan for Vulnerabilities
```bash
trivy image flask-app:test
```

### 3. Run Attack Simulations
```bash
# Container attacks (run inside container)
docker exec -it <container_id> bash
./scripts/attacks/simulate_attacks.sh

# Web attacks (run from local machine)
python3 scripts/attacks/web_attacks.py http://<your-alb-url>
```

### 4. Monitor Alerts
```bash
# View CloudWatch logs
aws logs tail /ecs/production/flask-app --follow

# Check ECS service
aws ecs describe-services --cluster production-cluster --services flask-app-service
```

## 📊 Monitoring & Logs

### CloudWatch Logs
```bash
# Tail application logs
aws logs tail /ecs/production/flask-app --follow

# View VPC Flow Logs
aws logs tail /aws/vpc/production-flow-logs --follow
```

### ECS Monitoring
```bash
# Service status
aws ecs describe-services \
  --cluster production-cluster \
  --services flask-app-service

# Task list
aws ecs list-tasks \
  --cluster production-cluster \
  --service-name flask-app-service
```

### Container Insights
Access via AWS Console:
- CloudWatch → Container Insights
- View CPU, Memory, Network metrics
- Monitor task and service performance

## 🔧 Troubleshooting

### Container Won't Start
```bash
# Check ECS service events
aws ecs describe-services --cluster production-cluster --services flask-app-service

# View task logs
aws logs tail /ecs/production/flask-app --since 1h
```

### Deployment Fails
```bash
# Check GitHub Actions logs
# View in GitHub UI: Actions tab → Latest workflow

# Check Terraform state
cd terraform
terraform show
```

### High Vulnerability Count
```bash
# Scan locally
cd app
trivy image --severity HIGH,CRITICAL secure-flask-app:latest

# Update base image and dependencies
# Rebuild and rescan
```

## 📚 Documentation

- [Architecture Diagram](docs/diagrams/architecture.png)
- [Security Report](docs/reports/security-assessment.pdf)
- [Falco Rules Documentation](security/falco-rules/README.md)
- [Deployment Guide](docs/deployment-guide.md)

## 🎓 Learning Outcomes

By completing this project, you will learn:

- ✅ Docker security best practices
- ✅ CI/CD pipeline implementation
- ✅ Container vulnerability management
- ✅ Terraform infrastructure as code
- ✅ AWS ECS and Fargate
- ✅ Runtime security monitoring
- ✅ Security automation
- ✅ DevSecOps workflows

## 🧹 Cleanup

To destroy all resources:

```bash
./scripts/deployment/deploy.sh destroy
```

This will:
- Destroy all Terraform-managed resources
- Remove ECR repositories (images will be deleted)
- Delete CloudWatch log groups
- Clean up VPC and networking

**Note**: This action is irreversible!

## 📝 Deliverables Checklist

- [x] Containerized application with security hardening
- [x] Complete CI/CD pipeline with GitHub Actions
- [x] Vulnerability scanning (Trivy)
- [x] Container signing (Cosign)
- [x] Private ECR repository
- [x] ECS deployment with Terraform
- [x] Runtime monitoring (Falco)
- [x] Custom security rules
- [x] Attack simulation scripts
- [x] CloudWatch logging
- [x] Architecture diagrams
- [x] Comprehensive documentation
- [ ] 12-page security report
- [ ] Presentation slides

## 🤝 Contributing

This is an educational project. Feel free to:
- Fork and extend
- Add additional security features
- Improve documentation
- Share feedback

## 📄 License

MIT License - See LICENSE file for details

## 🔗 Resources

- [AWS ECS Best Practices](https://docs.aws.amazon.com/AmazonECS/latest/bestpracticesguide/)
- [Docker Security](https://docs.docker.com/engine/security/)
- [Trivy Documentation](https://aquasecurity.github.io/trivy/)
- [Falco Rules](https://falco.org/docs/rules/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

## 📞 Support

For issues or questions:
1. Check the troubleshooting section
2. Review GitHub Issues
3. Consult AWS documentation
4. Review CloudWatch logs

---

**Project Status**: ✅ Production Ready

Built with ❤️ for learning DevSecOps and cloud security