#!/bin/bash
# Build and push all services to AWS ECR

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVICES_DIR="$(dirname "$SCRIPT_DIR")"
cd "${SERVICES_DIR}"

REGION="us-east-1"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}   Deploy to AWS ECR                    ${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e ""

echo -e "${YELLOW}🔐 Logging into ECR...${NC}"
aws ecr get-login-password --region ${REGION} | docker login --username AWS --password-stdin ${ECR}
echo -e "${GREEN}✅ Login successful${NC}"
echo -e ""

SERVICES=("product-service" "cart-service" "user-service" "order-service" "shipping-service")

for SERVICE in "${SERVICES[@]}"; do
    echo -e "${BLUE}----------------------------------------${NC}"
    echo -e "${YELLOW}📦 Building ${SERVICE}...${NC}"
    echo -e "${BLUE}----------------------------------------${NC}"
    
    # Create ECR repo if not exists
    if aws ecr describe-repositories --repository-names "ecommerce/${SERVICE}" --region ${REGION} > /dev/null 2>&1; then
        echo -e "  ${GREEN}✓ Repository exists${NC}"
    else
        echo -e "  ${YELLOW}📁 Creating repository...${NC}"
        aws ecr create-repository --repository-name "ecommerce/${SERVICE}" --region ${REGION} > /dev/null 2>&1
        echo -e "  ${GREEN}✅ Repository created${NC}"
    fi
    
    # Build image
    echo -e "  ${YELLOW}🏗️  Building Docker image...${NC}"
    if docker build -t "ecommerce/${SERVICE}" "${SERVICES_DIR}/${SERVICE}"; then
        echo -e "  ${GREEN}✅ Build successful${NC}"
    else
        echo -e "  ${RED}❌ Build failed${NC}"
        continue
    fi
    
    # Tag image
    echo -e "  ${YELLOW}🏷️  Tagging image...${NC}"
    docker tag "ecommerce/${SERVICE}:latest" "${ECR}/ecommerce/${SERVICE}:latest"
    
    # Push image
    echo -e "  ${YELLOW}📤 Pushing to ECR...${NC}"
    if docker push "${ECR}/ecommerce/${SERVICE}:latest"; then
        echo -e "  ${GREEN}✅ ${SERVICE} deployed successfully!${NC}"
    else
        echo -e "  ${RED}❌ Push failed${NC}"
        continue
    fi
    
    echo -e ""
done

echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}🎉 All services pushed to ECR!${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e ""
echo -e "${YELLOW}ECR Repositories:${NC}"
for SERVICE in "${SERVICES[@]}"; do
    echo -e "  ${ECR}/ecommerce/${SERVICE}:latest"
done
echo -e ""
echo -e "${GREEN}✅ Ready for ECS deployment!${NC}"