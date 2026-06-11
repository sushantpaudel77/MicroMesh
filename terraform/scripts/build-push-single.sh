#!/bin/bash
set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

SERVICE=${1:-all}
ENV=${2:-dev}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Find services directory
if [ -d "${SCRIPT_DIR}/../services" ]; then
    ROOT_DIR="${SCRIPT_DIR}/.."
elif [ -d "${SCRIPT_DIR}/../../services" ]; then
    ROOT_DIR="${SCRIPT_DIR}/../.."
else
    echo -e "${RED}❌ Services directory not found!${NC}"
    exit 1
fi

REGION="us-east-1"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"
PROJECT="ecommerce"

# ============================================
# Determine which services to build
# ============================================
if [ "$SERVICE" = "all" ]; then
    SERVICES=(
        "product-service"
        "cart-service"
        "user-service"
        "order-service"
        "shipping-service"
    )
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE}  📦 Build & Deploy ALL Services${NC}"
    echo -e "${BLUE}============================================${NC}"
else
    SERVICES=("$SERVICE")
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE}  📦 Build & Deploy: ${SERVICE}${NC}"
    echo -e "${BLUE}============================================${NC}"
fi

echo -e "${YELLOW}Environment: ${ENV}${NC}"
echo ""

# ============================================
# Login to ECR (once)
# ============================================
echo -e "${YELLOW}🔐 Logging into ECR...${NC}"
aws ecr get-login-password --region "$REGION" | \
    docker login --username AWS --password-stdin "$ECR" || {
    echo -e "${RED}❌ ECR login failed!${NC}"
    exit 1
}
echo -e "${GREEN}✅ Done${NC}"
echo ""

# ============================================
# Build, Push & Deploy Each Service
# ============================================
for SVC in "${SERVICES[@]}"; do
    SERVICE_DIR="${ROOT_DIR}/services/${SVC}"
    
    if [ ! -d "$SERVICE_DIR" ]; then
        echo -e "${YELLOW}⚠️  ${SVC} not found, skipping...${NC}"
        continue
    fi
    
    SERVICE_KEY=$(echo "$SVC" | sed 's/-service//')
    TASK_FAMILY="${PROJECT}-${SERVICE_KEY}-${ENV}"
    CLUSTER="${PROJECT}-cluster-${ENV}"
    ECS_SERVICE_NAME="${PROJECT}-${SERVICE_KEY}-svc-${ENV}"
    
    echo -e "${BLUE}----------------------------------------${NC}"
    echo -e "${BLUE}  🔨 ${SVC}${NC}"
    echo -e "${BLUE}----------------------------------------${NC}"
    
    # Build
    echo -e "${YELLOW}Building...${NC}"
    cd "$SERVICE_DIR"
    
    aws ecr describe-repositories --repository-names "${PROJECT}/${SVC}" --region "$REGION" 2>/dev/null || \
        aws ecr create-repository --repository-name "${PROJECT}/${SVC}" --region "$REGION" > /dev/null 2>&1
    
    docker build -t "${PROJECT}/${SVC}:latest" . || { echo -e "${RED}❌ Build failed!${NC}"; continue; }
    
    # Push
    echo -e "${YELLOW}Pushing...${NC}"
    docker tag "${PROJECT}/${SVC}:latest" "${ECR}/${PROJECT}/${SVC}:latest"
    docker push "${ECR}/${PROJECT}/${SVC}:latest" || { echo -e "${RED}❌ Push failed!${NC}"; continue; }
    echo -e "${GREEN}✅ Image pushed${NC}"
    
    # Deploy (create new revision + update service)
    if aws ecs describe-task-definition --task-definition "$TASK_FAMILY" --region "$REGION" > /dev/null 2>&1; then
        
        # Save current task def to file
        aws ecs describe-task-definition \
            --task-definition "$TASK_FAMILY" \
            --region "$REGION" \
            --query 'taskDefinition' \
            --output json > /tmp/current-task-def.json
        
        # Clean up and save new
        python3 -c "
import json
with open('/tmp/current-task-def.json') as f:
    td = json.load(f)
for field in ['taskDefinitionArn', 'revision', 'status', 'requiresAttributes', 
              'compatibilities', 'registeredAt', 'registeredBy']:
    td.pop(field, None)
with open('/tmp/new-task-def.json', 'w') as f:
    json.dump(td, f, indent=2)
"
        
        # Register new revision
        NEW_REVISION=$(aws ecs register-task-definition \
            --cli-input-json "file:///tmp/new-task-def.json" \
            --region "$REGION" \
            --query 'taskDefinition.taskDefinitionArn' \
            --output text)
        
        echo -e "${GREEN}✅ New revision created${NC}"
        
        # Update service
        if aws ecs describe-services --cluster "$CLUSTER" --services "$ECS_SERVICE_NAME" --region "$REGION" \
            --query 'services[0].status' --output text 2>/dev/null | grep -q "ACTIVE"; then
            
            aws ecs update-service \
                --cluster "$CLUSTER" \
                --service "$ECS_SERVICE_NAME" \
                --task-definition "$NEW_REVISION" \
                --force-new-deployment \
                --region "$REGION" > /dev/null
            
            echo -e "${GREEN}✅ Service updating...${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  Task definition not found - deploy infra first${NC}"
    fi
    
    echo ""
done

# ============================================
# Done
# ============================================
echo -e "${BLUE}============================================${NC}"
echo -e "${GREEN}✅ All done!${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""
echo -e "${YELLOW}Check status:${NC}"
echo -e "  aws ecs list-services --cluster ${PROJECT}-cluster-${ENV} --region ${REGION}"