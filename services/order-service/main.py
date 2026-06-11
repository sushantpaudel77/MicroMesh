from fastapi import FastAPI, HTTPException, Header
from fastapi.middleware.cors import CORSMiddleware
from typing import List, Optional
from models import Order, OrderCreate, OrderItem
from database import get_db_cursor, init_db
from config import settings
import httpx
import boto3
import json
import base64
import uuid
import logging
from datetime import datetime, timedelta
from cache import cache

logger = logging.getLogger(__name__)

app = FastAPI(title="Order Service")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["https://dev.cloudforsushant.xyz", "https://cloudforsushant.xyz"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

def get_sns_client():
    if settings.environment == "local":
        return boto3.client(
            'sns',
            endpoint_url=settings.sns_endpoint,
            region_name=settings.aws_region,
            aws_access_key_id='test',
            aws_secret_access_key='test'
        )
    else:
        return boto3.client('sns', region_name=settings.aws_region)

@app.on_event("startup")
def startup_event():
    init_db()

@app.get("/health")
def health_check():
    return {"status": "healthy", "service": "order-service"}

def get_user_from_token(authorization: Optional[str]) -> tuple:
    """Extract user ID and email from JWT token. Returns (user_id, email)"""
    if not authorization:
        return ("test-user-123", "test-user-123@example.com")
    
    try:
        # Extract token from "Bearer <token>"
        token = authorization.replace("Bearer ", "")
        
        # Decode JWT payload (without verification for simplicity)
        # In production, you should verify the signature
        parts = token.split('.')
        if len(parts) != 3:
            return ("test-user-123", "test-user-123@example.com")
        
        # Decode payload (add padding if needed)
        payload = parts[1]
        payload += '=' * (4 - len(payload) % 4)
        decoded = base64.urlsafe_b64decode(payload)
        user_data = json.loads(decoded)
        
        # Extract 'sub' claim (user ID) and 'email' claim
        user_id = user_data.get('sub', 'test-user-123')
        email = user_data.get('email', f"{user_id}@example.com")
        return (user_id, email)
    except Exception as e:
        print(f"Error decoding token: {e}")
        return ("test-user-123", "test-user-123@example.com")


# In order-service/main.py
@app.post("/orders", response_model=Order)
async def create_order(order: OrderCreate, authorization: str = Header(None)):
    """Create order from cart with proper SNS payload"""
    user_id, user_email = get_user_from_token(authorization)
    
    async with httpx.AsyncClient() as client:
        # 1. Get user details
        user_response = await client.get(
            f"{settings.user_service_url}/users/cognito/{user_id}",
            headers={"X-User-Email": user_email}
        )
        user = user_response.json()
        
        # 2. Get cart items
        cart_response = await client.get(
            f"{settings.cart_service_url}/cart",
            headers={"X-User-Id": user_id}
        )
        cart = cart_response.json()
        
        if not cart.get('items'):
            raise HTTPException(status_code=400, detail="Cart is empty")
        
        # 3. Get product details for each item
        items_with_details = []
        total_amount = 0
        for item in cart['items']:
            product_response = await client.get(
                f"{settings.product_service_url}/products/{item['product_id']}"
            )
            product = product_response.json()
            
            item_detail = {
                'product_id': item['product_id'],
                'product_name': product['name'],
                'quantity': item['quantity'],
                'unit_price': float(item['price']),
                'total_price': float(item['price'] * item['quantity']),
                'category': product.get('category', ''),
                'sku': product.get('sku', item['product_id'])
            }
            items_with_details.append(item_detail)
            total_amount += item_detail['total_price']
            
            # Update inventory
            await client.put(
                f"{settings.product_service_url}/products/{item['product_id']}/inventory",
                json={"quantity": -item['quantity']}
            )
        
        # 4. Calculate totals
        shipping_cost = 10.00  # Can be dynamic based on shipping method
        tax = total_amount * 0.10
        order_total = total_amount + shipping_cost + tax
        
        # 5. Create order in database
        with get_db_cursor() as cursor:
            cursor.execute("""
                INSERT INTO orders (user_id, user_email, total_amount, status)
                VALUES (%s, %s, %s, %s)
                RETURNING *
            """, (user['id'], user['email'], order_total, 'Order Placed'))
            
            order_record = cursor.fetchone()
            order_id = order_record['id']
            
            for item in items_with_details:
                cursor.execute("""
                    INSERT INTO order_items (order_id, product_id, quantity, price)
                    VALUES (%s, %s, %s, %s)
                """, (order_id, item['product_id'], item['quantity'], item['unit_price']))
        
        # 6. Clear cart
        await client.delete(
            f"{settings.cart_service_url}/cart",
            headers={"X-User-Id": user_id}
        )
        
        # 7. Prepare comprehensive SNS message
        correlation_id = f"corr-{order_id}-{uuid.uuid4().hex[:8]}"
        
        sns_message = {
            "event": "order_created",
            "version": "1.0",
            "timestamp": datetime.utcnow().isoformat() + "Z",
            "order": {
                "order_id": order_id,
                "user_id": user['id'],
                "user_email": user['email'],
                "user_name": user.get('name', ''),
                "total_amount": float(order_total),
                "currency": "USD",
                "status": "Order Placed",
                "created_at": datetime.utcnow().isoformat() + "Z",
                "shipping_address": {
                    "full_name": user.get('name', ''),
                    "address_line1": user.get('address', ''),
                    "address_line2": user.get('address2', ''),
                    "city": user.get('city', ''),
                    "state": user.get('state', ''),
                    "postal_code": user.get('postal_code', ''),
                    "country": user.get('country', ''),
                    "phone": user.get('phone', '')
                },
                "items": items_with_details,
                "payment": {
                    "payment_method": "default",
                    "transaction_id": f"txn_{order_id}_{int(datetime.utcnow().timestamp())}",
                    "payment_status": "completed",
                    "paid_amount": float(order_total)
                },
                "shipping_method": "Standard",
                "shipping_cost": float(shipping_cost),
                "tax": float(tax),
                "subtotal": float(total_amount),
                "discount": {
                    "coupon_code": None,
                    "discount_amount": 0.00
                },
                "estimated_delivery": (datetime.utcnow() + timedelta(days=5)).isoformat() + "Z"
            },
            "metadata": {
                "source": "order-service",
                "environment": settings.environment,
                "correlation_id": correlation_id,
                "trace_id": correlation_id  # For distributed tracing
            }
        }
        
        # 8. Publish to SNS with attributes for filtering
        try:
            sns = get_sns_client()
            sns.publish(
                TopicArn=settings.sns_topic_arn,
                Message=json.dumps(sns_message),
                Subject=f"New Order #{order_id} - ${order_total:.2f}",
                MessageAttributes={
                    'event_type': {
                        'DataType': 'String',
                        'StringValue': 'order_created'
                    },
                    'order_status': {
                        'DataType': 'String',
                        'StringValue': 'Order Placed'
                    },
                    'user_id': {
                        'DataType': 'Number',
                        'StringValue': str(user['id'])
                    },
                    'order_total': {
                        'DataType': 'Number',
                        'StringValue': str(order_total)
                    },
                    'items_count': {
                        'DataType': 'Number',
                        'StringValue': str(len(items_with_details))
                    },
                    'environment': {
                        'DataType': 'String',
                        'StringValue': settings.environment
                    }
                }
            )
            logger.info(f"Order #{order_id} published to SNS successfully")
        except Exception as e:
            logger.error(f"Failed to publish order #{order_id} to SNS: {e}")
            # Don't fail the order if SNS fails
            
        # Invalidate orders cache
        cache.delete(f"orders:recent:{user['id']}")
        return order_record


async def get_user_from_service(user_id: str):
    """Get user details from User Service"""
    async with httpx.AsyncClient() as client:
        try:
            response = await client.get(
                f"{settings.user_service_url}/users/cognito/{user_id}"
            )
            response.raise_for_status()
            return response.json()
        except Exception as e:
            raise HTTPException(status_code=400, detail=f"Failed to get user: {str(e)}")

@app.get("/orders", response_model=List[Order])
async def get_user_orders(authorization: str = Header(None)):
    """Get all orders for a user"""
    user_id, _ = get_user_from_token(authorization)  # Only need user_id here

    # Get user first
    user = await get_user_from_service(user_id)
    
    cache_key = f"orders:recent:{user['id']}"
    cache_orders = cache.get(cache_key)
    if cache_orders:
        return cache_orders
    
    # First get user's internal ID
    async with httpx.AsyncClient() as client:
        try:
            response = await client.get(f"{settings.user_service_url}/users/cognito/{user_id}")
            response.raise_for_status()
            user = response.json()
        except Exception as e:
            raise HTTPException(status_code=400, detail=f"Failed to get user: {str(e)}")
    
    with get_db_cursor() as cursor:
        cursor.execute("SELECT * FROM orders WHERE user_id = %s ORDER BY created_at DESC", (user['id'],))
        orders = cursor.fetchall()
        
        # Get items for each order
        result = []
        for order in orders:
            cursor.execute("SELECT * FROM order_items WHERE order_id = %s", (order['id'],))
            items = cursor.fetchall()
            
            order_dict = dict(order)
            order_dict['items'] = [
                OrderItem(product_id=item['product_id'], quantity=item['quantity'], price=item['price'])
                for item in items
            ]
            result.append(order_dict)
        
        return result

@app.get("/orders/{order_id}", response_model=Order)
def get_order(order_id: int):
    """Get order details"""
    with get_db_cursor() as cursor:
        cursor.execute("SELECT * FROM orders WHERE id = %s", (order_id,))
        order = cursor.fetchone()
        
        if not order:
            raise HTTPException(status_code=404, detail="Order not found")
        
        cursor.execute("SELECT * FROM order_items WHERE order_id = %s", (order_id,))
        items = cursor.fetchall()
        
        order_dict = dict(order)
        order_dict['items'] = [
            OrderItem(product_id=item['product_id'], quantity=item['quantity'], price=item['price'])
            for item in items
        ]
        
        return order_dict

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8004)
