from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from typing import List
from models import Product, UpdateInventoryRequest
from database import get_products_table
from boto3.dynamodb.conditions import Attr
from config import settings
import uuid
import logging
from cache import cache

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="Product Service")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["https://dev.cloudforsushant.xyz", "https://cloudforsushant.xyz"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.on_event("startup")
async def startup_event():
    logger.info(f"Starting Product Service with config:")
    logger.info(f"  Environment: {settings.environment}")
    logger.info(f"  AWS Region: {settings.aws_region}")
    logger.info(f"  Products Table: {settings.products_table}")
    if settings.environment == "local":
        logger.info(f"  DynamoDB Endpoint: {settings.dynamodb_endpoint}")

@app.get("/health")
def health_check():
    return {"status": "healthy", "service": "product-service"}

@app.get("/products", response_model=List[Product])
def list_products(category: str = None):
    
    # Check cache first
    cache_key = f"products:all:{category or 'all'}" 
    cache_data = cache.get(cache_key)
    if cache_data:
        return cache_data
    
    table = get_products_table()
    if category:
        response = table.scan(FilterExpression=Attr('category').eq(category))
    else:
        response = table.scan()
    
    products = response.get('Items', [])
    
    # Store in cache for 2 min
    cache.set(cache_key, products, ttl=120)
    return products

@app.get("/products/{product_id}", response_model=Product)
def get_product(product_id: str):
    cache_key = f"product:{product_id}"
    cached_data = cache.get(cache_key)
    if cached_data:
        return cached_data
    
    table = get_products_table()
    response = table.get_item(Key={'product_id': product_id})
    
    if 'Item' not in response:
        raise HTTPException(status_code=404, detail="Product not found")
    
    product = response['Item']
    cache.set(cache_key, product, ttl=300)  # Cache for 5 minutes
    return product

@app.put("/products/{product_id}/inventory")
def update_inventory(product_id: str, request: UpdateInventoryRequest):
    table = get_products_table()
    try:
        response = table.update_item(
            Key={'product_id': product_id},
            UpdateExpression="SET stock = stock + :qty",
            ExpressionAttributeValues={':qty': request.quantity},
            ReturnValues="UPDATED_NEW"
        )
        # Invalidate cache
        cache.delete(f"product:{product_id}")
        cache.delete_pattern("products:all:*")
        return {"product_id": product_id, "new_stock": response['Attributes']['stock']}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8001)
