#!/bin/bash
# Complete Deployment Script for Container Security Pipeline

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
AWS_REGION=${AWS_REGION:-us-east-1}
ENVIRONMENT=${ENVIRONMENT:-production}
PROJECT_NAME="container-security-pipeline"

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_prerequisites() {
    log_info "Checking prerequisites..."
    
    commands=("aws" "terraform" "docker" "jq")
    
    for cmd in "${commands[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            log_error "$cmd is not installed. Please install it first."
            exit 1
        fi
    done
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        log_error "AWS credentials not configured. Run 'aws configure'"
        exit 1
    fi
    
    log_success "All prerequisites met"
}

init_terraform() {
    log_info "Initializing Terraform..."
    cd terraform
    
    if [ ! -f "terraform.tfvars" ]; then
        log_warning "terraform.tfvars not found. Creating from template..."
        cat > terraform.tfvars <<EOF
aws_region          = "$AWS_REGION"
environment         = "$ENVIRONMENT"
ecr_repository_name = "secure-flask-app"
vpc_cidr            = "10.0.0.0/16"
EOF
    fi
    
    terraform init
    log_success "Terraform initialized"
    cd ..
}

plan_infrastructure() {
    log_info "Planning infrastructure..."
    cd terraform
    terraform plan -out=tfplan
    log_success "Terraform plan created"
    cd ..
}

apply_infrastructure() {
    log_info "Applying infrastructure..."
    cd terraform
    terraform apply tfplan
    
    # Get outputs
    ECR_URL=$(terraform output -raw ecr_repository_url)
    ALB_URL=$(terraform output -raw alb_url)
    
    log_success "Infrastructure deployed successfully"
    log_info "ECR Repository: $ECR_URL"
    log_info "Application URL: $ALB_URL"
    
    # Save outputs for later use
    cat > ../deployment_outputs.env <<EOF
ECR_URL=$ECR_URL
ALB_URL=$ALB_URL
AWS_REGION=$AWS_REGION
ENVIRONMENT=$ENVIRONMENT
EOF
    
    cd ..
}

build_and_push_image() {
    log_info "Building and pushing Docker image..."
    
    # Load outputs
    source deployment_outputs.env
    
    # Login to ECR
    aws ecr get-login-password --region $AWS_REGION | \
        docker login --username AWS --password-stdin $ECR_URL
    
    # Build image
    cd app
    IMAGE_TAG=$(git rev-parse --short HEAD 2>/dev/null || echo "latest")
    docker build -t secure-flask-app:$IMAGE_TAG .
    docker tag secure-flask-app:$IMAGE_TAG $ECR_URL:$IMAGE_TAG
    docker tag secure-flask-app:$IMAGE_TAG $ECR_URL:latest
    
    log_info "Scanning image with Trivy..."
    trivy image --severity HIGH,CRITICAL secure-flask-app:$IMAGE_TAG
    
    # Push to ECR
    log_info "Pushing image to ECR..."
    docker push $ECR_URL:$IMAGE_TAG
    docker push $ECR_URL:latest
    
    log_success "Image pushed to ECR: $ECR_URL:$IMAGE_TAG"
    cd ..
}

update_ecs_service() {
    log_info "Updating ECS service..."
    
    source deployment_outputs.env
    
    # Force new deployment
    aws ecs update-service \
        --cluster ${ENVIRONMENT}-cluster \
        --service flask-app-service \
        --force-new-deployment \
        --region $AWS_REGION
    
    log_success "ECS service updated"
}

wait_for_deployment() {
    log_info "Waiting for deployment to stabilize..."
    
    source deployment_outputs.env
    
    aws ecs wait services-stable \
        --cluster ${ENVIRONMENT}-cluster \
        --services flask-app-service \
        --region $AWS_REGION
    
    log_success "Deployment stable"
}

verify_deployment() {
    log_info "Verifying deployment..."
    
    source deployment_outputs.env
    
    # Wait a bit for ALB to be ready
    sleep 10
    
    # Test health endpoint
    if curl -s -f "$ALB_URL/health" > /dev/null; then
        log_success "Application is healthy!"
        log_info "Application URL: $ALB_URL"
    else
        log_error "Health check failed"
        exit 1
    fi
}

setup_monitoring() {
    log_info "Setting up monitoring dashboards..."
    
    # This would create CloudWatch dashboards
    # For now, just output the log group
    log_info "CloudWatch Log Group: /ecs/$ENVIRONMENT/flask-app"
    log_info "View logs: aws logs tail /ecs/$ENVIRONMENT/flask-app --follow"
}

print_summary() {
    source deployment_outputs.env
    
    echo ""
    echo "==============================================="
    echo "Deployment Summary"
    echo "==============================================="
    echo "Application URL: $ALB_URL"
    echo "ECR Repository: $ECR_URL"
    echo "AWS Region: $AWS_REGION"
    echo "Environment: $ENVIRONMENT"
    echo ""
    echo "Next steps:"
    echo "  1. Access application: curl $ALB_URL"
    echo "  2. View logs: aws logs tail /ecs/$ENVIRONMENT/flask-app --follow"
    echo "  3. Run attack simulations: scripts/attacks/web_attacks.py $ALB_URL"
    echo "  4. Monitor security: Check Falco alerts in logs"
    echo "==============================================="
}

# Main deployment flow
main() {
    echo "==============================================="
    echo "Container Security Pipeline Deployment"
    echo "==============================================="
    echo ""
    
    check_prerequisites
    init_terraform
    plan_infrastructure
    
    read -p "Apply infrastructure? (yes/no): " -r
    if [[ $REPLY =~ ^[Yy]es$ ]]; then
        apply_infrastructure
        build_and_push_image
        update_ecs_service
        wait_for_deployment
        verify_deployment
        setup_monitoring
        print_summary
    else
        log_info "Deployment cancelled"
        exit 0
    fi
}

# Handle script arguments
case "${1:-deploy}" in
    "deploy")
        main
        ;;
    "destroy")
        log_warning "Destroying infrastructure..."
        cd terraform
        terraform destroy -auto-approve
        log_success "Infrastructure destroyed"
        ;;
    "update")
        build_and_push_image
        update_ecs_service
        wait_for_deployment
        verify_deployment
        ;;
    *)
        echo "Usage: $0 {deploy|destroy|update}"
        exit 1
        ;;
esac