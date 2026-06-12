#!/bin/bash

ENV=${1:-dev}
REGION=${2:-us-east-1}

# Get bucket directly from S3 list
BUCKET=$(aws s3 ls --region "$REGION" 2>/dev/null | grep "ecommerce-frontend-${ENV}" | awk '{print $3}')

if [ -z "$BUCKET" ]; then
    echo "❌ Could not find S3 bucket!"
    echo "Available buckets:"
    aws s3 ls --region "$REGION"
    exit 1
fi

echo "Bucket: $BUCKET"
echo "Uploading images to: s3://${BUCKET}/images/products/"
aws s3 sync "$(dirname "$0")/product-images/" "s3://${BUCKET}/images/products/" --region "$REGION"
echo "✅ Done!"
