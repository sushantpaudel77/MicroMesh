#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Find global directory
if [ -d "${SCRIPT_DIR}/../global" ]; then
    GLOBAL_DIR="${SCRIPT_DIR}/../global"
elif [ -d "${SCRIPT_DIR}/../../terraform/global" ]; then
    GLOBAL_DIR="${SCRIPT_DIR}/../../terraform/global"
else
    echo "❌ Global directory not found!"
    exit 1
fi

echo "============================================"
echo "  🔧 Initializing Terraform Backend"
echo "============================================"
echo ""

cd "$GLOBAL_DIR"

echo "📦 Initializing Terraform..."
terraform init

echo ""
echo "📋 Planning backend resources..."
terraform plan -out=tfplan

echo ""
echo "⚡ Creating S3 backend bucket..."
terraform apply tfplan

echo ""
echo "✅ Backend initialized successfully!"
echo ""
echo "📋 Backend Configuration:"
terraform output backend_config