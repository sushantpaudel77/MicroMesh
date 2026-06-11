import os
import boto3
from pydantic_settings import BaseSettings
from pydantic import ConfigDict

class Settings(BaseSettings):
    model_config = ConfigDict(frozen=False, env_file=".env")
    environment: str = "local"
    aws_region: str = "us-east-1"
    dynamodb_endpoint: str = "http://localstack:4566"
    sns_endpoint: str = "http://localstack:4566"
    shipping_table: str = "ecommerce-shipping"  # Default for local
    sns_topic_arn: str = "arn:aws:sns:us-east-1:000000000000:shipping-events"
    
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        if os.getenv('SHIPPING_TABLE'):
            self.shipping_table = os.getenv('SHIPPING_TABLE')
        if self.environment != "local":
            self._load_from_parameter_store()
    
    def _load_from_parameter_store(self):
        try:
            # Use AWS_REGION environment variable (set in task definition)
            region = os.getenv('AWS_REGION', 'us-east-1')
            print(f"DEBUG: environment={self.environment}")
            print(f"DEBUG: AWS_REGION={region}")
            ssm = boto3.client('ssm', region_name=region)
            
            # Get parameters from SSM Parameter Store
            response = ssm.get_parameters(
                Names=[
                    f'/ecommerce/{self.environment}/aws/region',
                    f'/ecommerce/{self.environment}/shipping/table',
                    f'/ecommerce/{self.environment}/sns/shipping-topic-arn'
                ],
                WithDecryption=True
            )
            
            # Update values
            for param in response['Parameters']:
                name = param['Name']
                value = param['Value']
                
                if name.endswith('/aws/region'):
                    self.aws_region = value
                elif name.endswith('/shipping/table'):
                    self.shipping_table = value
                elif name.endswith('/sns/shipping-topic-arn'):
                    self.sns_topic_arn = value
                    
        except Exception as e:
            print(f"Warning: Could not load parameters from Parameter Store: {e}")
            print("Using default/environment variable values")

settings = Settings()