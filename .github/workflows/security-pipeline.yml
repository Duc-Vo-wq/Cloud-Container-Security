name: Container Security Pipeline

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]
  workflow_dispatch:

env:
  AWS_REGION: us-east-1
  ECR_REPOSITORY: secure-flask-app
  ECS_CLUSTER: secure-container-cluster
  ECS_SERVICE: flask-app-service
  CONTAINER_NAME: flask-app

jobs:
  security-scan:
    name: Security Scanning
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v4

    - name: Set up Python
      uses: actions/setup-python@v5
      with:
        python-version: '3.11'

    - name: Install dependencies
      run: |
        cd app
        pip install -r requirements.txt

    - name: Run security linting (Bandit)
      run: |
        pip install bandit
        bandit -r app/ -f json -o bandit-report.json || true
        
    - name: Upload Bandit report
      uses: actions/upload-artifact@v4
      with:
        name: bandit-report
        path: bandit-report.json

  build-and-scan:
    name: Build and Scan Container
    runs-on: ubuntu-latest
    needs: security-scan
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v4

    - name: Set up Docker Buildx
      uses: docker/setup-buildx-action@v3

    - name: Build Docker image
      run: |
        docker build -t ${{ env.ECR_REPOSITORY }}:${{ github.sha }} ./app
        docker tag ${{ env.ECR_REPOSITORY }}:${{ github.sha }} ${{ env.ECR_REPOSITORY }}:latest

    - name: Run Trivy vulnerability scanner
      uses: aquasecurity/trivy-action@master
      with:
        image-ref: ${{ env.ECR_REPOSITORY }}:${{ github.sha }}
        format: 'sarif'
        output: 'trivy-results.sarif'
        severity: 'CRITICAL,HIGH'

    - name: Upload Trivy results to GitHub Security
      uses: github/codeql-action/upload-sarif@v3
      with:
        sarif_file: 'trivy-results.sarif'

    - name: Run Trivy vulnerability scanner (JSON)
      uses: aquasecurity/trivy-action@master
      with:
        image-ref: ${{ env.ECR_REPOSITORY }}:${{ github.sha }}
        format: 'json'
        output: 'trivy-results.json'

    - name: Upload Trivy JSON report
      uses: actions/upload-artifact@v4
      with:
        name: trivy-report
        path: trivy-results.json

    - name: Check for critical vulnerabilities
      run: |
        CRITICAL=$(cat trivy-results.json | jq '[.Results[].Vulnerabilities[]? | select(.Severity=="CRITICAL")] | length')
        HIGH=$(cat trivy-results.json | jq '[.Results[].Vulnerabilities[]? | select(.Severity=="HIGH")] | length')
        
        echo "Critical vulnerabilities: $CRITICAL"
        echo "High vulnerabilities: $HIGH"
        
        if [ "$CRITICAL" -gt 0 ]; then
          echo "::error::Found $CRITICAL critical vulnerabilities"
          exit 1
        fi

    - name: Save Docker image
      run: |
        docker save ${{ env.ECR_REPOSITORY }}:${{ github.sha }} -o container-image.tar
        
    - name: Upload Docker image artifact
      uses: actions/upload-artifact@v4
      with:
        name: container-image
        path: container-image.tar
        retention-days: 1

  sign-and-push:
    name: Sign and Push to ECR
    runs-on: ubuntu-latest
    needs: build-and-scan
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v4

    - name: Download Docker image
      uses: actions/download-artifact@v4
      with:
        name: container-image

    - name: Load Docker image
      run: |
        docker load -i container-image.tar

    - name: Install Cosign
      uses: sigstore/cosign-installer@v3

    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v4
      with:
        aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
        aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        aws-region: ${{ env.AWS_REGION }}

    - name: Login to Amazon ECR
      id: login-ecr
      uses: aws-actions/amazon-ecr-login@v2

    - name: Tag and push image to ECR
      env:
        ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
      run: |
        docker tag ${{ env.ECR_REPOSITORY }}:${{ github.sha }} $ECR_REGISTRY/${{ env.ECR_REPOSITORY }}:${{ github.sha }}
        docker tag ${{ env.ECR_REPOSITORY }}:${{ github.sha }} $ECR_REGISTRY/${{ env.ECR_REPOSITORY }}:latest
        docker push $ECR_REGISTRY/${{ env.ECR_REPOSITORY }}:${{ github.sha }}
        docker push $ECR_REGISTRY/${{ env.ECR_REPOSITORY }}:latest

    - name: Sign container image with Cosign
      env:
        ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
        COSIGN_EXPERIMENTAL: 1
      run: |
        cosign sign --yes $ECR_REGISTRY/${{ env.ECR_REPOSITORY }}:${{ github.sha }}

    - name: Generate SBOM
      env:
        ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
      run: |
        docker run --rm \
          -v /var/run/docker.sock:/var/run/docker.sock \
          aquasec/trivy image \
          --format cyclonedx \
          --output sbom.json \
          $ECR_REGISTRY/${{ env.ECR_REPOSITORY }}:${{ github.sha }}

    - name: Upload SBOM
      uses: actions/upload-artifact@v4
      with:
        name: sbom
        path: sbom.json

  deploy:
    name: Deploy to ECS
    runs-on: ubuntu-latest
    needs: sign-and-push
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v4

    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v4
      with:
        aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
        aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        aws-region: ${{ env.AWS_REGION }}

    - name: Login to Amazon ECR
      id: login-ecr
      uses: aws-actions/amazon-ecr-login@v2

    - name: Update ECS task definition
      id: task-def
      env:
        ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
      run: |
        aws ecs describe-task-definition \
          --task-definition flask-app-task \
          --query taskDefinition > task-definition.json
        
        cat task-definition.json | jq --arg IMAGE "$ECR_REGISTRY/${{ env.ECR_REPOSITORY }}:${{ github.sha }}" \
          '.containerDefinitions[0].image = $IMAGE' | \
          jq 'del(.taskDefinitionArn, .revision, .status, .requiresAttributes, .compatibilities, .registeredAt, .registeredBy)' \
          > new-task-definition.json

    - name: Deploy to Amazon ECS
      uses: aws-actions/amazon-ecs-deploy-task-definition@v1
      with:
        task-definition: new-task-definition.json
        service: ${{ env.ECS_SERVICE }}
        cluster: ${{ env.ECS_CLUSTER }}
        wait-for-service-stability: true

    - name: Verify deployment
      run: |
        echo "Deployment completed successfully!"
        echo "Image: ${{ steps.login-ecr.outputs.registry }}/${{ env.ECR_REPOSITORY }}:${{ github.sha }}"