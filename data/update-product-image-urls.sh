#!/bin/bash

# Update product image URLs with CloudFront domain
# Usage: ./update-product-image-urls.sh <environment> <region>

ENV=${1:-dev}
REGION=${2:-us-east-1}

# Get CloudFront domain
CF_DOMAIN=$(aws ssm get-parameter \
    --name "/ecommerce/${ENV}/frontend-url" \
    --region "$REGION" \
    --query 'Parameter.Value' \
    --output text 2>/dev/null | sed 's|https://||' || echo "")

if [ -z "$CF_DOMAIN" ]; then
    echo "❌ Could not get CloudFront domain!"
    exit 1
fi

echo "CloudFront Domain: $CF_DOMAIN"

cd "$(dirname "$0")"
python3 -c "
import json
cf_domain = '${CF_DOMAIN}'
with open('products.json') as f:
    products = json.load(f)
for p in products:
    pid = p['product_id']
    p['image_url'] = f'https://{cf_domain}/images/products/{pid}.jpg'
with open('products.json', 'w') as f:
    json.dump(products, f, indent=2)
"

echo "✅ Product image URLs updated!"