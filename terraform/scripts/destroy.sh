#!/bin/bash
set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

ENV=${1:-dev}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Find environment directory
if [ -d "${SCRIPT_DIR}/../environments/${ENV}" ]; then
    ENV_DIR="${SCRIPT_DIR}/../environments/${ENV}"
elif [ -d "${SCRIPT_DIR}/../../terraform/environments/${ENV}" ]; then
    ENV_DIR="${SCRIPT_DIR}/../../terraform/environments/${ENV}"
else
    echo -e "${RED}❌ Environment '${ENV}' not found!${NC}"
    echo -e "${YELLOW}Available: dev, stage, prod${NC}"
    exit 1
fi

echo -e "${RED}============================================${NC}"
echo -e "${RED}  ⚠️  DESTROYING: ${ENV} ENVIRONMENT${NC}"
echo -e "${RED}============================================${NC}"
echo ""

cd "$ENV_DIR"

# ============================================
# Step 1: Init Terraform
# ============================================
echo -e "${YELLOW}📋 Step 1: Initializing Terraform...${NC}"
terraform init -reconfigure -backend-config="key=${ENV}/terraform.tfstate" > /dev/null 2>&1 || {
    echo -e "${RED}❌ Terraform init failed! Check backend bucket.${NC}"
    exit 1
}
echo -e "${GREEN}✅ Initialized${NC}"
echo ""

# ============================================
# Step 2: Empty S3 buckets first
# ============================================
echo -e "${YELLOW}📋 Step 2: Emptying S3 buckets...${NC}"

# Get bucket name from terraform state (may fail if state is empty)
BUCKET_NAME=$(terraform output -raw frontend_bucket 2>/dev/null || echo "")

if [ -n "$BUCKET_NAME" ] && [ "$BUCKET_NAME" != "null" ] && [ "$BUCKET_NAME" != "" ]; then
    echo -e "  ${YELLOW}🗑️  Emptying: ${BUCKET_NAME}${NC}"
    
    # Delete all objects
    aws s3 rm "s3://${BUCKET_NAME}" --recursive --region us-east-1 2>/dev/null || true
    
    # Delete all object versions (if versioning enabled)
    aws s3api delete-objects \
        --bucket "$BUCKET_NAME" \
        --delete "$(aws s3api list-object-versions \
            --bucket "$BUCKET_NAME" \
            --query '{Objects: Versions[].{Key:Key,VersionId:VersionId}}' \
            --region us-east-1 2>/dev/null || echo '{"Objects":[]}')" \
        --region us-east-1 2>/dev/null || true
    
    # Delete delete markers
    aws s3api delete-objects \
        --bucket "$BUCKET_NAME" \
        --delete "$(aws s3api list-object-versions \
            --bucket "$BUCKET_NAME" \
            --query '{Objects: DeleteMarkers[].{Key:Key,VersionId:VersionId}}' \
            --region us-east-1 2>/dev/null || echo '{"Objects":[]}')" \
        --region us-east-1 2>/dev/null || true
    
    echo -e "  ${GREEN}✅ Bucket emptied${NC}"
else
    echo -e "  ${YELLOW}⚠️  No S3 bucket found in outputs${NC}"
fi
echo ""

# ============================================
# Step 3: Scale down ECS services (faster destroy)
# ============================================
echo -e "${YELLOW}📋 Step 3: Scaling down ECS services...${NC}"

CLUSTER="${ENV}-ecommerce-cluster"
SERVICES=$(aws ecs list-services \
    --cluster "$CLUSTER" \
    --region us-east-1 \
    --query 'serviceArns[]' \
    --output text 2>/dev/null || echo "")

if [ -n "$SERVICES" ] && [ "$SERVICES" != "None" ]; then
    for SVC in $SERVICES; do
        SVC_NAME=$(basename "$SVC")
        echo -e "  Scaling down: ${SVC_NAME}"
        aws ecs update-service \
            --cluster "$CLUSTER" \
            --service "$SVC_NAME" \
            --desired-count 0 \
            --region us-east-1 > /dev/null 2>&1 || true
    done
    echo -e "  ${GREEN}✅ ECS services scaled down${NC}"
fi
echo ""

# ============================================
# Step 4: Confirmation
# ============================================
echo -e "${RED}╔══════════════════════════════════════════════╗${NC}"
echo -e "${RED}║  ⚠️  THIS WILL DESTROY EVERYTHING!           ║${NC}"
echo -e "${RED}║  - VPC, Subnets, NAT, IGW                    ║${NC}"
echo -e "${RED}║  - RDS Database (data will be lost!)          ║${NC}"
echo -e "${RED}║  - DynamoDB Tables (data will be lost!)       ║${NC}"
echo -e "${RED}║  - ECS Cluster, Services, Tasks               ║${NC}"
echo -e "${RED}║  - Lambda, SNS, SQS                           ║${NC}"
echo -e "${RED}║  - API Gateway, ALB                            ║${NC}"
echo -e "${RED}║  - CloudFront, S3 Bucket                       ║${NC}"
echo -e "${RED}║  - Cognito User Pool                           ║${NC}"
echo -e "${RED}║  - All Security Groups, IAM Roles              ║${NC}"
echo -e "${RED}╚══════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${YELLOW}Type '${ENV}' to confirm:${NC}"
read -r CONFIRM

if [ "$CONFIRM" != "$ENV" ]; then
    echo -e "${GREEN}✅ Cancelled${NC}"
    exit 0
fi

echo ""
echo -e "${YELLOW}Type 'YES-DESTROY-ALL-NOW' for final confirmation:${NC}"
read -r FINAL_CONFIRM

if [ "$FINAL_CONFIRM" != "YES-DESTROY-ALL-NOW" ]; then
    echo -e "${GREEN}✅ Cancelled${NC}"
    exit 0
fi

# ============================================
# Step 5: Terraform Destroy
# ============================================
echo ""
echo -e "${RED}💣 DESTROYING ${ENV} environment...${NC}"
echo ""

cd "$ENV_DIR"
terraform destroy -var-file="terraform.tfvars" -auto-approve || {
    echo ""
    echo -e "${RED}❌ Destroy failed! Some resources may remain.${NC}"
    echo -e "${YELLOW}Try running again or check AWS Console manually.${NC}"
    exit 1
}

echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}  ✅ ${ENV} environment destroyed!${NC}"
echo -e "${GREEN}============================================${NC}"