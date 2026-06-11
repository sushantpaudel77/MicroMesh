"""
Local test script for Lambda function
Run: python local-test.py
"""

import json
from lambda_function import lambda_handler

# Load test event
with open('test-event.json', 'r') as f:
    event = json.load(f)

# Mock context
class MockContext:
    function_name = "local-test"
    memory_limit_in_mb = 256
    invoked_function_arn = "arn:aws:lambda:local:test"
    aws_request_id = "local-test-123"

# Test
print("Testing Lambda function locally...")
print("")

result = lambda_handler(event, MockContext())

print("")
print(f"Result: {json.dumps(result, indent=2)}")