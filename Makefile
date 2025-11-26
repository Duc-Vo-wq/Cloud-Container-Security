.PHONY: help build scan test deploy destroy clean

help:
	@echo "Cloud Container Security Pipeline - Available Commands:"
	@echo ""
	@echo "  make build        - Build Docker image locally"
	@echo "  make scan         - Scan image for vulnerabilities"
	@echo "  make test         - Run application tests"
	@echo "  make deploy       - Deploy complete infrastructure"
	@echo "  make update       - Update application only"
	@echo "  make destroy      - Destroy all infrastructure"
	@echo "  make logs         - Tail CloudWatch logs"
	@echo "  make attack-sim   - Run attack simulations"
	@echo "  make clean        - Clean local artifacts"
	@echo ""

build:
	@echo "Building Docker image..."
	cd app && docker build -t secure-flask-app:latest .

scan:
	@echo "Scanning image with Trivy..."
	trivy image --severity HIGH,CRITICAL secure-flask-app:latest

test:
	@echo "Running tests..."
	cd app && python -m pytest tests/ || echo "No tests yet"

deploy:
	@echo "Deploying infrastructure..."
	chmod +x scripts/deployment/deploy.sh
	./scripts/deployment/deploy.sh deploy

update:
	@echo "Updating application..."
	./scripts/deployment/deploy.sh update

destroy:
	@echo "Destroying infrastructure..."
	./scripts/deployment/deploy.sh destroy

logs:
	@echo "Tailing CloudWatch logs..."
	aws logs tail /ecs/production/flask-app --follow

attack-sim:
	@echo "Running attack simulations..."
	@if [ -f deployment_outputs.env ]; then \
		. deployment_outputs.env && \
		python3 scripts/attacks/web_attacks.py $$ALB_URL; \
	else \
		echo "Error: deployment_outputs.env not found. Run 'make deploy' first."; \
	fi

clean:
	@echo "Cleaning local artifacts..."
	find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	find . -type f -name "*.pyc" -delete
	find . -type f -name "*.log" -delete
	rm -f deployment_outputs.env
	rm -f *.tar
	docker system prune -f

init:
	@echo "Initializing project..."
	@echo "Installing local development dependencies..."
	cd app && pip install -r requirements.txt
	@echo "Installing Trivy..."
	@which trivy > /dev/null || echo "Please install Trivy: https://aquasecurity.github.io/trivy/"
	@echo "Checking AWS CLI..."
	@which aws > /dev/null || echo "Please install AWS CLI"
	@echo "Checking Terraform..."
	@which terraform > /dev/null || echo "Please install Terraform"
	@echo ""
	@echo "Setup complete! Run 'make deploy' to start."