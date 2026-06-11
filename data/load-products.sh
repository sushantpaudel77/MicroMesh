name: CI/CD Pipeline - E-Commerce Platform

on:
  workflow_dispatch:
    inputs:
      environment:
        description: 'Environment to deploy'
        required: true
        type: choice
        options:
          - dev
          - prod
      action:
        description: 'Action'
        required: true
        type: choice
        options:
          - apply
          - destroy

env:
  AWS_REGION: us-east-1
  ECR_REGISTRY: ${{ secrets.AWS_ACCOUNT_ID }}.dkr.ecr.${{ secrets.AWS_REGION }}.amazonaws.com

jobs:
  # Build & Push
  build-and-push:
    name: Build & Push All Images
    runs-on: ubuntu-latest
    strategy:
      matrix:
        service:
          - product-service
          - cart-service
          - user-service
          - order-service
          - shipping-service
    steps:
      - uses: actions/checkout@v4
      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ secrets.AWS_REGION }}
      - name: Login to ECR
        uses: aws-actions/amazon-ecr-login@v2
      - name: Create ECR Repo
        run: |
          aws ecr describe-repositories --repository-names ecommerce/${{ matrix.service }} --region $AWS_REGION 2>/dev/null || \
            aws ecr create-repository --repository-name ecommerce/${{ matrix.service }} --region $AWS_REGION
      - name: Build and Push
        uses: docker/build-push-action@v5
        with:
          context: services/${{ matrix.service }}
          file: services/${{ matrix.service }}/Dockerfile
          push: true
          tags: ${{ env.ECR_REGISTRY }}/ecommerce/${{ matrix.service }}:latest

  # Terraform
  terraform:
    name: Terraform ${{ inputs.action }} - ${{ inputs.environment }}
    needs: build-and-push
    runs-on: ubuntu-latest
    environment:
      name: ${{ inputs.environment }}
    steps:
      - uses: actions/checkout@v4
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ secrets.AWS_REGION }}

      - name: Create tfvars
        run: |
          cat > terraform/environments/${{ inputs.environment }}/terraform.auto.tfvars << EOF
          admin_email = "${{ secrets.ADMIN_EMAIL }}"
          domain_name = "${{ secrets.DOMAIN_NAME }}"
          acm_certificate_arn = "${{ secrets.ACM_CERT_ARN }}"
          environment = "${{ inputs.environment }}"
          aws_region = "us-east-1"
          project_name = "ecommerce"
          time_period_start = "2026-06-01_00:00"
          EOF

      - name: Terraform ${{ inputs.action }}
        run: |
          cd terraform/environments/${{ inputs.environment }}
          terraform init -reconfigure \
            -backend-config="bucket=ecommerce-terraform-state-cloudnerd" \
            -backend-config="key=${{ inputs.environment }}/terraform.tfstate" \
            -backend-config="region=us-east-1"
          
          if [ "${{ inputs.action }}" = "destroy" ]; then
            terraform destroy -auto-approve
          else
            terraform apply -auto-approve
          fi