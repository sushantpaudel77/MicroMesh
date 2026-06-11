#!/bin/bash
# Package Lambda function for deployment
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
OUTPUT_DIR="${ROOT_DIR}/terraform/modules/lambda"

echo "📦 Packaging Lambda function..."

cd "$SCRIPT_DIR"

# Create zip with only the Python file (no dependencies needed)
zip -j "${OUTPUT_DIR}/shipping-processor.zip" lambda_function.py

echo "✅ Lambda package created: ${OUTPUT_DIR}/shipping-processor.zip"
echo "   Size: $(du -h "${OUTPUT_DIR}/shipping-processor.zip" | cut -f1)"