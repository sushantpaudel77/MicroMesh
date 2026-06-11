#!/bin/bash

# Load products into DynamoDB
# Usage: ./load-products.sh <environment> <region>
# Example: ./load-products.sh dev us-east-1

set -e

ENV=${1:-dev}
REGION=${2:-us-east-1}
PROJECT="ecommerce"

# ============================================
# Get table names dynamically
# ============================================
TABLE_NAME="${PROJECT}-${ENV}-products"
CARTS_TABLE="${PROJECT}-${ENV}-cart"

# Try to get from SSM first (if Terraform deployed)
TABLE_NAME_SSM=$(aws ssm get-parameter \
    --name "/${PROJECT}/${ENV}/dynamodb/products-table" \
    --region "$REGION" \
    --query 'Parameter.Value' \
    --output text 2>/dev/null || echo "")

if [ -n "$TABLE_NAME_SSM" ] && [ "$TABLE_NAME_SSM" != "None" ]; then
    TABLE_NAME="$TABLE_NAME_SSM"
fi

CARTS_TABLE_SSM=$(aws ssm get-parameter \
    --name "/${PROJECT}/${ENV}/dynamodb/cart-table" \
    --region "$REGION" \
    --query 'Parameter.Value' \
    --output text 2>/dev/null || echo "")

if [ -n "$CARTS_TABLE_SSM" ] && [ "$CARTS_TABLE_SSM" != "None" ]; then
    CARTS_TABLE="$CARTS_TABLE_SSM"
fi

echo "============================================"
echo "  📦 Load Products into DynamoDB"
echo "============================================"
echo "Environment: $ENV"
echo "Products Table: $TABLE_NAME"
echo "Carts Table: $CARTS_TABLE"
echo "Region: $REGION"
echo ""

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "Error: jq is required but not installed."
    echo "Install with: sudo apt-get install jq (Ubuntu/Debian) or brew install jq (Mac)"
    exit 1
fi

# Check if products table exists
echo "Checking if table $TABLE_NAME exists..."
if ! aws dynamodb describe-table --table-name "$TABLE_NAME" --region "$REGION" > /dev/null 2>&1; then
    echo "❌ Table $TABLE_NAME does not exist!"
    echo "Deploy infrastructure first or create table manually."
    exit 1
fi
echo "✓ Table $TABLE_NAME exists"
echo ""

# Read products from JSON file
PRODUCTS_FILE="$(dirname "$0")/products.json"

if [ ! -f "$PRODUCTS_FILE" ]; then
    echo "Error: products.json not found at $PRODUCTS_FILE"
    exit 1
fi

# Count total products
TOTAL=$(jq length "$PRODUCTS_FILE")
echo "Found $TOTAL products to load"
echo ""

# Load each product
COUNTER=0
SUCCESS=0
FAILED=0

jq -c '.[]' "$PRODUCTS_FILE" | while read -r product; do
    COUNTER=$((COUNTER + 1))
    
    PRODUCT_ID=$(echo "$product" | jq -r '.product_id')
    NAME=$(echo "$product" | jq -r '.name')
    
    echo -n "[$COUNTER/$TOTAL] $NAME ($PRODUCT_ID) ... "
    
    ITEM=$(echo "$product" | jq '{
        product_id: {S: .product_id},
        name: {S: .name},
        description: {S: .description},
        price: {N: (.price | tostring)},
        stock: {N: (.stock | tostring)},
        category: {S: .category},
        image_url: {S: .image_url}
    }')
    
    if aws dynamodb put-item \
        --table-name "$TABLE_NAME" \
        --item "$ITEM" \
        --region "$REGION" > /dev/null 2>&1; then
        echo "✅"
    else
        echo "❌"
    fi
done

echo ""
echo "============================================"
echo "✅ Loading complete!"
echo "============================================"
echo ""
echo "Verify: aws dynamodb scan --table-name $TABLE_NAME --region $REGION --query 'Count'"