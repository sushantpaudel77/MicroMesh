#!/bin/bash

ENV=${1:-dev}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Find environment directory
if [ -d "${SCRIPT_DIR}/../environments/${ENV}" ]; then
    ENV_DIR="${SCRIPT_DIR}/../environments/${ENV}"
elif [ -d "${SCRIPT_DIR}/../../terraform/environments/${ENV}" ]; then
    ENV_DIR="${SCRIPT_DIR}/../../terraform/environments/${ENV}"
else
    echo "❌ Environment '${ENV}' not found!"
    exit 1
fi

cd "$ENV_DIR"
terraform init -reconfigure -backend-config="key=${ENV}/terraform.tfstate" > /dev/null 2>&1

echo "========================================="
echo "  📊 ${ENV} Environment Status"
echo "========================================="
echo ""

echo "🔧 Terraform Outputs:"
terraform output 2>/dev/null || echo "  No outputs available"
echo ""

echo "📦 ECS Services:"
aws ecs list-services \
    --cluster "ecommerce-cluster-${ENV}" \
    --region us-east-1 \
    --query 'serviceArns[]' \
    --output table 2>/dev/null || echo "  No services found"
echo ""

echo "🗄️ DynamoDB Tables:"
aws dynamodb list-tables \
    --region us-east-1 \
    --query "TableNames[?contains(@, '${ENV}')]" \
    --output table 2>/dev/null || echo "  No tables found"
echo ""

echo "📨 SQS Queues:"
aws sqs list-queues \
    --region us-east-1 \
    --query "QueueUrls[?contains(@, '${ENV}')]" \
    --output table 2>/dev/null || echo "  No queues found"
echo ""

echo "🌐 API Gateway:"
aws apigatewayv2 get-apis \
    --region us-east-1 \
    --query "Items[?contains(Name, '${ENV}')].ApiEndpoint" \
    --output table 2>/dev/null || echo "  No APIs found"
echo ""

echo "📧 SNS Topics:"
aws sns list-topics \
    --region us-east-1 \
    --query "Topics[?contains(TopicArn, '${ENV}')].TopicArn" \
    --output table 2>/dev/null || echo "  No topics found"