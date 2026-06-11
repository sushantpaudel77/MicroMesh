import boto3
from config import settings

def get_dynamodb_resource():
    """Get DynamoDB resource based on environment"""
    if settings.environment == "local":
        return boto3.resource(
            'dynamodb',
            endpoint_url=settings.dynamodb_endpoint,
            region_name=settings.aws_region,
            aws_access_key_id='test',
            aws_secret_access_key='test'
        )
    else:
        # Don't set endpoint_url - use default AWS endpoint
        return boto3.resource('dynamodb', region_name=settings.aws_region)

def get_shipping_table():
    """Get the shipping table"""
    dynamodb = get_dynamodb_resource()
    return dynamodb.Table(settings.shipping_table)