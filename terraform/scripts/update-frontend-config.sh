#!/bin/bash
set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

ENV=${1:-dev}
REGION="us-east-1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Find frontend directory
if [ -d "${SCRIPT_DIR}/../frontend/react-vite-app" ]; then
    FRONTEND_DIR="${SCRIPT_DIR}/../frontend/react-vite-app"
elif [ -d "${SCRIPT_DIR}/../../frontend/react-vite-app" ]; then
    FRONTEND_DIR="${SCRIPT_DIR}/../../frontend/react-vite-app"
else
    echo -e "${RED}❌ Frontend directory not found!${NC}"
    exit 1
fi

ENV_FILE="${FRONTEND_DIR}/.env"

echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}  🔧 Update Frontend .env${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""

# ============================================
# Get values from SSM Parameter Store
# ============================================
echo -e "${YELLOW}Fetching values from SSM...${NC}"

USER_POOL_ID=$(aws ssm get-parameter \
    --name "/ecommerce/${ENV}/cognito/user-pool-id" \
    --region "$REGION" \
    --query 'Parameter.Value' \
    --output text 2>/dev/null)

CLIENT_ID=$(aws ssm get-parameter \
    --name "/ecommerce/${ENV}/cognito/client-id" \
    --region "$REGION" \
    --query 'Parameter.Value' \
    --output text 2>/dev/null)

API_URL=$(aws ssm get-parameter \
    --name "/ecommerce/${ENV}/api-url" \
    --region "$REGION" \
    --query 'Parameter.Value' \
    --output text 2>/dev/null)

# ============================================
# Fallback: Try Terraform outputs
# ============================================
if [ -z "$API_URL" ] || [ "$API_URL" = "None" ]; then
    ENV_DIR="${SCRIPT_DIR}/../environments/${ENV}"
    if [ -d "$ENV_DIR" ]; then
        cd "$ENV_DIR"
        terraform init -reconfigure -backend-config="key=${ENV}/terraform.tfstate" > /dev/null 2>&1
        API_URL=$(terraform output -raw api_endpoint 2>/dev/null || echo "")
    fi
fi

# ============================================
# Validate
# ============================================
if [ -z "$USER_POOL_ID" ] || [ "$USER_POOL_ID" = "None" ]; then
    echo -e "${RED}❌ Could not get Cognito User Pool ID!${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}✅ Values fetched:${NC}"
echo -e "  User Pool ID:  ${USER_POOL_ID}"
echo -e "  Client ID:     ${CLIENT_ID}"
echo -e "  API URL:       ${API_URL}"
echo ""

# ============================================
# Write .env file
# ============================================
echo -e "${YELLOW}Writing .env file...${NC}"

cat > "$ENV_FILE" << EOF
VITE_COGNITO_USER_POOL_ID=${USER_POOL_ID}
VITE_COGNITO_USER_POOL_CLIENT_ID=${CLIENT_ID}
VITE_API_BASE_URL=${API_URL}
EOF

echo -e "${GREEN}✅ .env written!${NC}"
cat "$ENV_FILE"
echo ""

# ============================================
# Build frontend
# ============================================
echo -e "${YELLOW}🔨 Building frontend...${NC}"
cd "$FRONTEND_DIR"
npm install --silent 2>/dev/null || true
npm run build
echo -e "${GREEN}✅ Build complete!${NC}"
echo ""

# ============================================
# Deploy to S3
# ============================================
echo -e "${YELLOW}📤 Deploying to S3...${NC}"

ENV_DIR="${SCRIPT_DIR}/../environments/${ENV}"
if [ -d "$ENV_DIR" ]; then
    cd "$ENV_DIR"
    BUCKET=$(terraform output -raw frontend_bucket 2>/dev/null || echo "")
    
    if [ -n "$BUCKET" ] && [ "$BUCKET" != "None" ]; then
        echo -e "  Bucket: ${BUCKET}"
        aws s3 sync "${FRONTEND_DIR}/dist/" "s3://${BUCKET}/" --delete
        
        CF_ID=$(terraform output -raw cloudfront_id 2>/dev/null || echo "")
        if [ -n "$CF_ID" ] && [ "$CF_ID" != "None" ]; then
            echo -e "  Invalidating CloudFront: ${CF_ID}"
            aws cloudfront create-invalidation --distribution-id "$CF_ID" --paths "/*" > /dev/null
        fi
        
        echo -e "${GREEN}✅ Frontend deployed!${NC}"
    else
        echo -e "${YELLOW}⚠️  S3 bucket not found${NC}"
    fi
fi

echo ""
echo -e "${BLUE}============================================${NC}"
echo -e "${GREEN}✅ Done!${NC}"
echo -e "${BLUE}============================================${NC}"