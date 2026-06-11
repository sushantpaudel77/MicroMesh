#!/bin/bash

# Upload product images to S3
# Usage: ./upload-images-to-s3.sh <environment> <region>

ENV=${1:-dev}
REGION=${2:-us-east-1}

# Get bucket name dynamically
BUCKET=$(aws ssm get-parameter \
    --name "/ecommerce/${ENV}/frontend-url" \
    --region "$REGION" \
    --query 'Parameter.Value' \
    --output text 2>/dev/null | sed 's|https://||' | cut -d'.' -f1 || echo "")

if [ -z "$BUCKET" ]; then
    BUCKET=$(aws s3 ls | grep "ecommerce-frontend-${ENV}" | awk '{print $3}')
fi

if [ -z "$BUCKET" ]; then
    echo "❌ Could not find S3 bucket!"
    exit 1
fi

echo "Uploading images to: s3://${BUCKET}/images/products/"
aws s3 sync "$(dirname "$0")/product-images/" "s3://${BUCKET}/images/products/" --region "$REGION"
echo "✅ Done!"