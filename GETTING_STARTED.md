# Getting Started - Step-by-Step Guide

This guide will walk you through setting up and deploying the Cloud Container Security Pipeline from scratch.

## 📋 Prerequisites Setup

### 1. Install Required Tools

#### AWS CLI
```bash
# macOS
brew install awscli

# Linux
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Windows
# Download from: https://awscli.amazonaws.com/AWSCLIV2.msi
```

#### Docker Desktop
- macOS/Windows: Download from [docker.com](https://www.docker.com/products/docker-desktop)
- Linux: `sudo apt-get install docker.io` or `sudo yum install docker`

#### Terraform
```bash
# macOS
brew install terraform

# Linux
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
unzip terraform_1.6.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/

# Windows
# Download from: https://www.terraform.io/downloads
```

#### Trivy (Vulnerability Scanner)
```bash
# macOS
brew install trivy

# Linux
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
echo "deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee -a /etc/apt/sources.list.d/trivy.list
sudo apt-get update
sudo apt-get install trivy
```

### 2. Configure AWS

#### Create AWS Account
1. Go to [aws.amazon.com](https://aws.amazon.com)
2. Create a new account (free tier eligible)
3. Verify your email and set up payment method

#### Create IAM User
1. Log into AWS Console
2. Navigate to IAM → Users → Add User
3. User name: `container-security-admin`
4. Enable: ✅ Programmatic access
5. Attach policies:
   - `AmazonEC2ContainerRegistryFullAccess`
   - `AmazonECS_FullAccess`
   - `AmazonVPCFullAccess`
   - `IAMFullAccess`
   - `CloudWatchLogsFullAccess`
6. Save Access Key ID and Secret Access Key

#### Configure AWS CLI
```bash
aws configure

# Enter when prompted:
# AWS Access Key ID: YOUR_ACCESS_KEY
# AWS Secret Access Key: YOUR_SECRET_KEY
# Default region: us-east-1
# Default output format: json

# Test configuration
aws sts get-caller-identity
```

### 3. Set Up GitHub Repository

#### Create Repository
```bash
# On GitHub website
1. Go to github.com
2. Click "New Repository"
3. Name: "cloud-container-security"
4. Initialize with README: NO
5. Create repository

# Clone locally
git clone https://github.com/YOUR_USERNAME/cloud-container-security.git
cd cloud-container-security
```

#### Add GitHub Secrets
1. Go to Repository → Settings → Secrets and Variables → Actions
2. Add secrets:
   - `AWS_ACCESS_KEY_ID`: Your AWS access key
   - `AWS_SECRET_ACCESS_KEY`: Your AWS secret key

## 🚀 Project Setup

### Step 1: Create Project Structure

```bash
# Create all directories
mkdir -p app/{templates,static}
mkdir -p .github/workflows
mkdir -p terraform/{modules/{vpc,ecr,ecs},environments}
mkdir -p security/falco-rules
mkdir -p docs/{diagrams,reports}
mkdir -p scripts/{deployment,attacks}
mkdir -p tests
```

### Step 2: Add Application Files

Copy all the artifact files I provided earlier:

1. **app/app.py** - Main Flask application
2. **app/requirements.txt** - Python dependencies
3. **app/Dockerfile** - Secure container image
4. **app/.dockerignore** - Docker ignore file
5. **app/templates/index.html** - Frontend

### Step 3: Add Terraform Configuration

Copy these Terraform files:

1. **terraform/main.tf** - Main infrastructure
2. **terraform/variables.tf** - Variables
3. **terraform/outputs.tf** - Outputs
4. **terraform/modules/vpc/** - VPC module files
5. **terraform/modules/ecr/** - ECR module files
6. **terraform/modules/ecs/** - ECS module files

### Step 4: Add CI/CD Pipeline

Copy:
1. **.github/workflows/security-pipeline.yml** - GitHub Actions workflow

### Step 5: Add Security Configuration

Copy:
1. **security/falco-rules/custom_rules.yaml** - Falco rules
2. **security/falco-rules/falco.yaml** - Falco config

### Step 6: Add Scripts

Copy:
1. **scripts/deployment/deploy.sh** - Deployment script
2. **scripts/attacks/simulate_attacks.sh** - Container attacks
3. **scripts/attacks/web_attacks.py** - Web attacks

### Step 7: Add Documentation

Copy:
1. **README.md** - Main documentation
2. **GETTING_STARTED.md** - This file
3. **.gitignore** - Git ignore
4. **Makefile** - Quick commands

## 🧪 Test Locally First

### 1. Build the Docker Image

```bash
cd app
docker build -t secure-flask-app:test .
```

### 2. Scan for Vulnerabilities

```bash
trivy image --severity HIGH,CRITICAL secure-flask-app:test
```

If you see critical vulnerabilities, update the base image or dependencies.

### 3. Run Container Locally

```bash
docker run -d -p 5000:5000 --name flask-test secure-flask-app:test

# Test endpoints
curl http://localhost:5000/health
curl http://localhost:5000/api/info
curl http://localhost:5000/

# View logs
docker logs flask-test

# Stop and remove
docker stop flask-test
docker rm flask-test
```

## 🌩️ Deploy to AWS

### Option 1: Using Make Commands (Recommended)

```bash
# Initialize (install deps, check tools)
make init

# Build locally
make build

# Scan for vulnerabilities
make scan

# Deploy everything
make deploy
```

The deploy command will:
1. Initialize Terraform
2. Create a plan
3. Ask for confirmation
4. Deploy all infrastructure
5. Build and push container
6. Deploy to ECS
7. Verify deployment

### Option 2: Manual Deployment

```bash
# Make script executable
chmod +x scripts/deployment/deploy.sh

# Run deployment
./scripts/deployment/deploy.sh deploy
```

### What Gets Created

The deployment creates:
- **VPC** with public and private subnets
- **NAT Gateways** for private subnet internet access
- **ECR Repository** for container images
- **ECS Cluster** (Fargate)
- **ECS Service** with 2 tasks
- **Application Load Balancer**
- **Security Groups** with least privilege
- **IAM Roles** for ECS tasks
- **CloudWatch Log Groups**
- **VPC Flow Logs**

### Deployment Time

- **First deployment**: 10-15 minutes
- **Updates**: 3-5 minutes

## 🔍 Verify Deployment

### 1. Check Application

```bash
# Get the ALB URL from outputs
source deployment_outputs.env
echo $ALB_URL

# Test health endpoint
curl $ALB_URL/health

# Test in browser
open http://$ALB_URL
```

### 2. View Logs

```bash
# Real-time logs
make logs

# Or manually
aws logs tail /ecs/production/flask-app --follow
```

### 3. Check ECS Service

```bash
aws ecs describe-services \
  --cluster production-cluster \
  --services flask-app-service \
  --region us-east-1
```

## 🛡️ Test Security Features

### 1. Run Vulnerability Scan

This already happened in CI/CD, but you can run manually:

```bash
# Scan the deployed image
ECR_URL=$(terraform -chdir=terraform output -raw ecr_repository_url)
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $ECR_URL
docker pull $ECR_URL:latest
trivy image $ECR_URL:latest
```

### 2. Simulate Attacks

```bash
# Web application attacks
make attack-sim

# Or manually
python3 scripts/attacks/web_attacks.py http://your-alb-url
```

### 3. Monitor Security Alerts

```bash
# Watch for Falco alerts in logs
aws logs tail /ecs/production/flask-app --follow | grep -i "falco\|alert\|warning"
```

## 📊 Monitor Your Deployment

### CloudWatch Dashboard

1. Go to AWS Console → CloudWatch
2. Container Insights → ECS
3. Select your cluster: `production-cluster`
4. View metrics: CPU, Memory, Network

### Application Logs

```bash
# Tail logs
aws logs tail /ecs/production/flask-app --follow

# Get specific time range
aws logs tail /ecs/production/flask-app --since 1h

# Search logs
aws logs filter-log-events \
  --log-group-name /ecs/production/flask-app \
  --filter-pattern "ERROR"
```

### ECS Console

1. AWS Console → ECS
2. Clusters → production-cluster
3. View: Services, Tasks, Metrics

## 🔄 Update Application

When you make code changes:

```bash
# Option 1: Using make
make update

# Option 2: Manual
./scripts/deployment/deploy.sh update
```

This will:
1. Build new image
2. Scan for vulnerabilities
3. Push to ECR
4. Update ECS service
5. Perform rolling update

## 🧹 Clean Up

### Delete Everything

```bash
# Option 1: Using make
make destroy

# Option 2: Manual
./scripts/deployment/deploy.sh destroy
```

⚠️ **Warning**: This will delete ALL resources and is irreversible!

### Partial Cleanup

```bash
# Just clean local artifacts
make clean

# Delete specific resources via Terraform
cd terraform
terraform destroy -target=module.ecs
```

## 🐛 Troubleshooting

### Issue: Terraform Fails

```bash
# Check state
cd terraform
terraform show

# Re-initialize
terraform init -upgrade

# Check for specific resource errors
terraform plan
```

### Issue: Container Won't Start

```bash
# Check ECS events
aws ecs describe-services --cluster production-cluster --services flask-app-service

# Check task failures
aws ecs list-tasks --cluster production-cluster --desired-status STOPPED

# View task logs
aws logs tail /ecs/production/flask-app --since 30m
```

### Issue: High Vulnerability Count

```bash
# Update base image in Dockerfile
# Change: FROM python:3.11-slim
# To: FROM python:3.11-alpine (smaller, fewer vulns)

# Update dependencies
cd app
pip install --upgrade -r requirements.txt
pip freeze > requirements.txt

# Rebuild and scan
docker build -t secure-flask-app:test .
trivy image secure-flask-app:test
```

### Issue: Can't Access Application

```bash
# Check security groups
aws ec2 describe-security-groups --filters "Name=group-name,Values=*alb*"

# Check ALB health
aws elbv2 describe-target-health \
  --target-group-arn $(aws elbv2 describe-target-groups \
    --names production-tg \
    --query 'TargetGroups[0].TargetGroupArn' \
    --output text)

# Check service
aws ecs describe-services \
  --cluster production-cluster \
  --services flask-app-service
```

## 📚 Next Steps

After successful deployment:

1. **Study the Architecture**: Review how components interact
2. **Analyze Security**: Look at Trivy scan results, Falco rules
3. **Test Resilience**: Stop tasks and watch auto-recovery
4. **Run Attacks**: Use simulation scripts and monitor alerts
5. **Write Report**: Document findings, vulnerabilities, mitigations
6. **Create Diagrams**: Use draw.io or Lucidchart
7. **Prepare Presentation**: 10-12 slides covering architecture, security, results

## 💡 Tips

- **Use AWS Free Tier**: Most services qualify (first 12 months)
- **Monitor Costs**: Set up billing alerts in AWS Console
- **Keep Learning**: Read AWS documentation, security best practices
- **Iterate**: Start simple, add complexity gradually
- **Document Everything**: Keep notes of issues and solutions

## 🎯 Project Completion Checklist

- [ ] All files created and organized
- [ ] Local Docker build successful
- [ ] Vulnerability scan passing (no critical issues)
- [ ] AWS infrastructure deployed
- [ ] Application accessible via ALB
- [ ] CI/CD pipeline configured
- [ ] Security scanning working
- [ ] Falco rules deployed
- [ ] Attack simulations run
- [ ] Logs and monitoring verified
- [ ] Documentation complete
- [ ] Architecture diagrams created
- [ ] Security report written
- [ ] Presentation slides prepared

## 🆘 Getting Help

1. Check the main [README.md](README.md)
2. Review [Troubleshooting](#-troubleshooting) section
3. Check CloudWatch logs for errors
4. Review Terraform state: `terraform show`
5. Consult AWS documentation
6. Check GitHub Issues (if public repo)

---

Good luck with your project! 🚀

Remember: Security is a journey, not a destination. Keep learning and improving!