#!/bin/bash
set -e

ENV=${1:-dev}
REGION=${2:-us-east-1}
PROJECT="ecommerce"
TABLE_NAME="${PROJECT}-${ENV}-products"

echo "Loading products into $TABLE_NAME..."

if ! command -v jq &> /dev/null; then
    echo "Installing jq..."
    sudo apt-get install -y jq
fi

PRODUCTS_FILE="$(dirname "$0")/products.json"

if [ ! -f "$PRODUCTS_FILE" ]; then
    echo "Error: products.json not found"
    exit 1
fi

TOTAL=$(jq length "$PRODUCTS_FILE")
echo "Loading $TOTAL products..."

jq -c '.[]' "$PRODUCTS_FILE" | while read -r product; do
    PRODUCT_ID=$(echo "$product" | jq -r '.product_id')
    NAME=$(echo "$product" | jq -r '.name')
    
    ITEM=$(echo "$product" | jq '{
        product_id: {S: .product_id},
        name: {S: .name},
        description: {S: .description},
        price: {N: (.price | tostring)},
        stock: {N: (.stock | tostring)},
        category: {S: .category},
        image_url: {S: .image_url}
    }')
    
    aws dynamodb put-item \
        --table-name "$TABLE_NAME" \
        --item "$ITEM" \
        --region "$REGION" > /dev/null 2>&1
    
    echo "  ✅ $NAME"
done

echo "✅ Done!"
