#!/bin/bash
set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# ============================================
# Configuration
# ============================================
ENV=${1:-dev}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Find environment directory
if [ -d "${SCRIPT_DIR}/../environments/${ENV}" ]; then
    ENV_DIR="${SCRIPT_DIR}/../environments/${ENV}"
elif [ -d "${SCRIPT_DIR}/../../terraform/environments/${ENV}" ]; then
    ENV_DIR="${SCRIPT_DIR}/../../terraform/environments/${ENV}"
else
    echo -e "${RED}❌ Environment '${ENV}' not found!${NC}"
    echo ""
    echo "Available environments:"
    find "$SCRIPT_DIR/.." -type d -name "dev" -o -name "stage" -o -name "prod" 2>/dev/null | grep -v node_modules | grep -v .terraform | head -5
    exit 1
fi

ROOT_DIR="$(dirname "$(dirname "$ENV_DIR")")"
SERVICES_DIR="${ROOT_DIR}/services"
FRONTEND_DIR="${ROOT_DIR}/frontend/react-vite-app"
LAMBDA_DIR="${ROOT_DIR}/lambda/order-shipment-processor"

# ============================================
# Auto-detect AWS region
# ============================================
REGION=$(aws configure get region 2>/dev/null || echo "us-east-1")

# ============================================
# Auto-detect state bucket
# ============================================
# Check if bucket exists in current region
STATE_BUCKET="ecommerce-terraform-state-cloudnerd"

# Get bucket's actual region
BUCKET_REGION=$(aws s3api get-bucket-location \
    --bucket "$STATE_BUCKET" \
    --query 'LocationConstraint' \
    --output text 2>/dev/null || echo "")

# Handle null for us-east-1
if [ "$BUCKET_REGION" = "None" ] || [ "$BUCKET_REGION" = "" ] || [ "$BUCKET_REGION" = "null" ]; then
    BUCKET_REGION="us-east-1"
fi

echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}  🚀 Deploying to: ${YELLOW}${ENV}${NC}"
echo -e "${BLUE}============================================${NC}"
echo -e "${YELLOW}Environment: ${ENV_DIR}${NC}"
echo -e "${YELLOW}AWS Region: ${REGION}${NC}"
echo -e "${YELLOW}State Bucket: ${STATE_BUCKET} (${BUCKET_REGION})${NC}"
echo ""

# ============================================
# Step 1: Verify AWS Credentials
# ============================================
echo -e "${YELLOW}📋 Step 1: Checking AWS credentials...${NC}"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text 2>/dev/null) || {
    echo -e "${RED}❌ AWS credentials not configured!${NC}"
    echo "Run: aws configure"
    exit 1
}
echo -e "${GREEN}✅ AWS Account: ${ACCOUNT_ID}${NC}"
echo ""

# ============================================
# Step 2: Login to ECR
# ============================================
echo -e "${YELLOW}📋 Step 2: Logging into ECR...${NC}"
ECR="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"

aws ecr get-login-password --region "$REGION" 2>/dev/null | \
    docker login --username AWS --password-stdin "$ECR" > /dev/null 2>&1 || {
    echo -e "${YELLOW}⚠️  Docker not available or ECR login skipped${NC}"
}
echo -e "${GREEN}✅ ECR ready${NC}"
echo ""

# ============================================
# Step 3: Build and Push Docker Images (Optional)
# ============================================
echo -e "${YELLOW}📋 Step 3: Build & Push Images? (y/n)${NC}"
read -r BUILD_IMAGES

if [ "$BUILD_IMAGES" = "y" ]; then
    if [ -d "$SERVICES_DIR" ]; then
        SERVICES=(
            "product-service"
            "cart-service"
            "user-service"
            "order-service"
            "shipping-service"
        )

        for SERVICE in "${SERVICES[@]}"; do
            if [ -d "${SERVICES_DIR}/${SERVICE}" ]; then
                echo -e "  ${BLUE}🔨 Building ${SERVICE}...${NC}"
                
                aws ecr describe-repositories \
                    --repository-names "ecommerce/${SERVICE}" \
                    --region "$REGION" 2>/dev/null || {
                    aws ecr create-repository \
                        --repository-name "ecommerce/${SERVICE}" \
                        --region "$REGION" > /dev/null 2>&1
                }
                
                cd "${SERVICES_DIR}/${SERVICE}"
                docker build -t "ecommerce/${SERVICE}:latest" . 2>/dev/null || true
                docker tag "ecommerce/${SERVICE}:latest" "${ECR}/ecommerce/${SERVICE}:latest" 2>/dev/null || true
                docker push "${ECR}/ecommerce/${SERVICE}:latest" 2>/dev/null || true
                
                echo -e "  ${GREEN}✅ ${SERVICE} done${NC}"
            fi
        done
    fi
else
    echo -e "${YELLOW}⏭️  Skipping image build${NC}"
fi
echo ""

# ============================================
# Step 4: Package Lambda
# ============================================
echo -e "${YELLOW}📋 Step 4: Packaging Lambda...${NC}"

LAMBDA_OUTPUT="${ENV_DIR}/../modules/lambda"
mkdir -p "$LAMBDA_OUTPUT"

LAMBDA_SOURCE=""
if [ -f "${LAMBDA_DIR}/lambda_function.py" ]; then
    LAMBDA_SOURCE="${LAMBDA_DIR}"
elif [ -f "${SCRIPT_DIR}/../../lambda/order-shipment-processor/lambda_function.py" ]; then
    LAMBDA_SOURCE="${SCRIPT_DIR}/../../lambda/order-shipment-processor"
elif [ -f "${ROOT_DIR}/lambda/order-shipment-processor/lambda_function.py" ]; then
    LAMBDA_SOURCE="${ROOT_DIR}/lambda/order-shipment-processor"
fi

if [ -n "$LAMBDA_SOURCE" ]; then
    cd "$LAMBDA_SOURCE"
    zip -j "${LAMBDA_OUTPUT}/shipping-processor.zip" lambda_function.py 2>/dev/null
    echo -e "${GREEN}✅ Lambda packaged${NC}"
else
    echo -e "${YELLOW}⚠️  Lambda not found, skipping${NC}"
fi
echo ""

# ============================================
# Step 5: Terraform Init
# ============================================
echo -e "${YELLOW}📋 Step 5: Terraform Init...${NC}"

cd "$ENV_DIR"

# Create backend config dynamically
cat > backend.tf << EOF
terraform {
  backend "s3" {
    bucket = "${STATE_BUCKET}"
    key    = "${ENV}/terraform.tfstate"
    region = "${BUCKET_REGION}"
    encrypt = true
  }
}
EOF

echo -e "  ${BLUE}Backend: ${STATE_BUCKET}/${ENV}/terraform.tfstate (region: ${BUCKET_REGION})${NC}"

terraform init -reconfigure -upgrade || {
    echo ""
    echo -e "${RED}❌ Terraform init failed!${NC}"
    echo ""
    echo -e "${YELLOW}Troubleshooting:${NC}"
    echo "  1. Check if bucket exists: aws s3 ls s3://${STATE_BUCKET}"
    echo "  2. Run init-backend.sh first: ./scripts/init-backend.sh"
    echo "  3. Or create bucket manually: aws s3 mb s3://${STATE_BUCKET} --region us-east-1"
    exit 1
}

echo ""

# ============================================
# Step 6: Terraform Plan
# ============================================
echo -e "${YELLOW}📋 Step 6: Planning...${NC}"
terraform plan -var-file="terraform.tfvars" -out=tfplan || {
    echo -e "${RED}❌ Terraform plan failed!${NC}"
    exit 1
}

echo ""

# ============================================
# Step 7: Confirm & Apply
# ============================================
echo -e "${YELLOW}⚠️  Apply infrastructure? (y/n)${NC}"
read -r CONFIRM

if [ "$CONFIRM" != "y" ]; then
    echo -e "${RED}❌ Cancelled${NC}"
    exit 1
fi

echo ""
echo -e "  ${BLUE}⚡ Applying...${NC}"
terraform apply tfplan || {
    echo -e "${RED}❌ Terraform apply failed!${NC}"
    exit 1
}

echo ""

# ============================================
# Step 8: Summary
# ============================================
echo -e "${BLUE}============================================${NC}"
echo -e "${GREEN}✅ Deployment Complete!${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""

terraform output 2>/dev/null || echo "Run 'terraform output' to see outputs"