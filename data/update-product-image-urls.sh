#!/bin/bash
# Update product image URLs with CloudFront domain

ENV=${1:-dev}
REGION=${2:-us-east-1}

# Get CloudFront domain (not Route53!)
CF_DOMAIN=$(aws cloudfront list-distributions \
    --region us-east-1 \
    --query "DistributionList.Items[?contains(Origins.Items[0].DomainName, 'ecommerce-frontend-${ENV}')].DomainName" \
    --output text 2>/dev/null)

if [ -z "$CF_DOMAIN" ] || [ "$CF_DOMAIN" = "None" ]; then
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

echo "✅ Product image URLs updated to use CloudFront!"