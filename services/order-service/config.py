import os
import boto3
from pydantic_settings import BaseSettings
from pydantic import ConfigDict

class Settings(BaseSettings):
    model_config = ConfigDict(frozen=False, env_file=".env")

    environment: str = "local"
    
    # Default values for local development
    aws_region: str = "us-east-1"
    db_host: str = "postgres"
    db_port: int = 5432
    db_name: str = "ecommercedb"
    db_user: str = "postgres"
    db_password: str = "postgres"  # Default for local
    
    # Service URLs
    cart_service_url: str = "http://cart-service:8002"
    user_service_url: str = "http://user-service:8003"
    product_service_url: str = "http://product-service:8001"
    
    # AWS SNS
    sns_endpoint: str = "http://localstack:4566"
    sns_topic_arn: str = "arn:aws:sns:us-east-1:000000000000:order-events"
    
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        
        if os.getenv('DB_HOST'):
            self.db_host = os.getenv('DB_HOST')
        if os.getenv('DB_NAME'):
            self.db_name = os.getenv('DB_NAME')
        if os.getenv('DB_USER'):
            self.db_user = os.getenv('DB_USER')
        if os.getenv('DB_PASSWORD'):
            self.db_password = os.getenv('DB_PASSWORD')
        if os.getenv('DB_PORT'):
            self.db_port = int(os.getenv('DB_PORT'))
        
        if self.environment != "local":
            self._load_from_parameter_store()
    
    def _load_from_parameter_store(self):
        try:
            region = os.getenv('AWS_REGION', 'us-east-1')
            ssm = boto3.client('ssm', region_name=region)
            
            # DB_PASSWORD comes from ECS Secrets injection, NOT from SSM!
            response = ssm.get_parameters(
                Names=[
                    f'/ecommerce/{self.environment}/aws/region',
                    f'/ecommerce/{self.environment}/db/host',
                    f'/ecommerce/{self.environment}/services/user-url',
                    f'/ecommerce/{self.environment}/services/cart-url',
                    f'/ecommerce/{self.environment}/services/product-url',
                    f'/ecommerce/{self.environment}/sns/order-topic-arn'
                ],
                WithDecryption=True
            )
            
            for param in response['Parameters']:
                name = param['Name']
                value = param['Value'].strip()
                
                if name.endswith('/aws/region'):
                    self.aws_region = value
                elif name.endswith('/db/host'):
                    self.db_host = value
                elif name.endswith('/services/user-url'):
                    self.user_service_url = value
                elif name.endswith('/services/cart-url'):
                    self.cart_service_url = value
                elif name.endswith('/services/product-url'):
                    self.product_service_url = value
                elif name.endswith('/sns/order-topic-arn'):
                    self.sns_topic_arn = value
                    
        except Exception as e:
            print(f"Warning: Could not load parameters from Parameter Store: {e}")
            print("Using default/environment variable values")

settings = Settings()