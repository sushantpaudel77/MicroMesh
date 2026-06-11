from fastapi import FastAPI, HTTPException, Header, Query
from fastapi.middleware.cors import CORSMiddleware
from typing import List, Optional
from models import (
    Shipment, ShipmentCreate, ShipmentStatusUpdate,
    ShipmentTracking, TrackingEvent
)
from database import get_shipping_table
from state_machine import ShipmentStateMachine
from models import ShipmentStatus
from datetime import datetime
import uuid
import json
import boto3
from config import settings
import logging
from cache import cache

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="Shipping Service")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["https://dev.cloudforsushant.xyz", "https://cloudforsushant.xyz"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

def get_sns_client():
    """Get SNS client based on environment"""
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
async def startup_event():
    """Log startup information"""
    logger.info(f"Starting Shipping Service...")
    logger.info(f"Environment: {settings.environment}")
    logger.info(f"AWS Region: {settings.aws_region}")
    logger.info(f"Shipping Table: {settings.shipping_table}")
    if settings.environment == "local":
        logger.info(f"DynamoDB Endpoint: {settings.dynamodb_endpoint}")

@app.get("/health")
def health_check():
    return {"status": "healthy", "service": "shipping-service"}


@app.post("/shipments", response_model=Shipment)
def create_shipment(shipment: ShipmentCreate):
    """Create new shipment - called by Lambda after order creation"""
    table = get_shipping_table()
    shipment_id = str(uuid.uuid4())
    
    now = datetime.utcnow().isoformat()
    
    # Generate tracking number
    tracking_number = f"TRK-{shipment_id[:8].upper()}-{shipment.order_id}"
    
    shipment_data = {
        'shipment_id': shipment_id,
        'order_id': shipment.order_id,
        'user_id': shipment.user_id,
        'user_email': shipment.user_email,
        'status': ShipmentStatus.PENDING.value,
        'tracking_number': tracking_number,
        'carrier': shipment.carrier or 'DefaultCarrier',
        'shipping_method': shipment.shipping_method or 'Standard',
        'origin_address': shipment.origin_address,
        'destination_address': shipment.destination_address or 'To be updated',
        'package_details': shipment.package_details or {},
        'tracking_history': [{
            'status': ShipmentStatus.PENDING.value,
            'location': 'System',
            'time': now,
            'description': 'Shipment created and pending processing'
        }],
        'estimated_delivery': None,
        'carrier_tracking_id': None,
        'created_at': now,
        'updated_at': now
    }
    
    try:
        table.put_item(Item=shipment_data)
        logger.info(f"Shipment created: {shipment_id} for order {shipment.order_id}")
        
        # Publish shipment created event to SNS
        try:
            sns = get_sns_client()
            sns.publish(
                TopicArn=settings.sns_topic_arn,
                Message=json.dumps({
                    'event': 'shipment_created',
                    'shipment_id': shipment_id,
                    'order_id': shipment.order_id,
                    'tracking_number': tracking_number,
                    'user_email': shipment.user_email
                }),
                Subject="Shipment Created"
            )
        except Exception as e:
            logger.warning(f"Failed to publish SNS event: {e}")
        
        return shipment_data
        
    except Exception as e:
        logger.error(f"Failed to create shipment: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.put("/shipments/{shipment_id}/status", response_model=Shipment)
def update_shipment_status(shipment_id: str, update: ShipmentStatusUpdate):
    """Update shipment status with state machine validation"""
    table = get_shipping_table()
    
    # Get current shipment
    response = table.get_item(Key={'shipment_id': shipment_id})
    if 'Item' not in response:
        raise HTTPException(status_code=404, detail="Shipment not found")
    
    shipment = response['Item']
    current_status = ShipmentStatus(shipment['status'])
    new_status = update.status
    
    # Validate state transition
    if not ShipmentStateMachine.can_transition(current_status, new_status):
        allowed = ShipmentStateMachine.get_allowed_transitions(current_status)
        raise HTTPException(
            status_code=400,
            detail=f"Invalid transition from {current_status.value} to {new_status.value}. "
                   f"Allowed transitions: {[s.value for s in allowed]}"
        )
    
    # Validate location requirement
    if ShipmentStateMachine.requires_location(new_status) and not update.location:
        raise HTTPException(
            status_code=400,
            detail=f"Location is required for status '{new_status.value}'"
        )
    
    # Create tracking event
    now = datetime.utcnow().isoformat()
    tracking_event = {
        'status': new_status.value,
        'location': update.location or 'System',
        'time': now,
        'description': update.description or f"Status updated to {new_status.value}"
    }
    
    # Build update expression
    update_parts = ["SET #status = :status, updated_at = :time"]
    expression_values = {
        ':status': new_status.value,
        ':time': now,
        ':event': [tracking_event]
    }
    expression_names = {
        '#status': 'status'
    }
    
    if update.carrier_tracking_id:
        update_parts.append("carrier_tracking_id = :tracking_id")
        expression_values[':tracking_id'] = update.carrier_tracking_id
    
    try:
        # Update shipment in DynamoDB
        table.update_item(
            Key={'shipment_id': shipment_id},
            UpdateExpression=f"""
                {', '.join(update_parts)},
                tracking_history = list_append(tracking_history, :event)
            """,
            ExpressionAttributeNames=expression_names,
            ExpressionAttributeValues=expression_values,
            ReturnValues="ALL_NEW"
        )
        
        # Invalidate cache for this shipment
        cache.delete(f"shipment:{shipment_id}")
        if 'tracking_number' in shipment:
            cache.delete(f"tracking:{shipment['tracking_number']}")
        logger.info(f"Cache invalidated for shipment: {shipment_id}")
        
        # Publish status update event
        try:
            sns = get_sns_client()
            sns.publish(
                TopicArn=settings.sns_topic_arn,
                Message=json.dumps({
                    'event': 'shipment_status_updated',
                    'shipment_id': shipment_id,
                    'order_id': shipment['order_id'],
                    'user_email': shipment.get('user_email'),
                    'status': new_status.value,
                    'location': update.location,
                    'tracking_event': tracking_event
                }),
                Subject=f"Shipment Status: {new_status.value}"
            )
        except Exception as e:
            logger.warning(f"Failed to publish SNS event: {e}")
        
        # Get updated shipment
        response = table.get_item(Key={'shipment_id': shipment_id})
        return response['Item']
        
    except Exception as e:
        logger.error(f"Failed to update shipment status: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/shipments/{shipment_id}", response_model=Shipment)
def get_shipment(shipment_id: str):
    """Get shipment details by shipment ID"""
    
    # Check cache first
    cache_key = f"shipment:{shipment_id}"
    cached = cache.get(cache_key)
    if cached:
        logger.info(f"Cache HIT for shipment: {shipment_id}")
        return cached
    
    table = get_shipping_table()
    response = table.get_item(Key={'shipment_id': shipment_id})
    
    if 'Item' not in response:
        raise HTTPException(status_code=404, detail="Shipment not found")
    
    shipment_data = response['Item']
    
    # Cache for 30 seconds
    cache.set(cache_key, shipment_data, ttl=30)
    logger.info(f"Cached shipment: {shipment_id}")
    
    return shipment_data

@app.get("/shipments/order/{order_id}", response_model=List[Shipment])
def get_shipments_by_order(order_id: int):
    """Get all shipments for an order"""
    
    # Check cache
    cache_key = f"shipments:order:{order_id}"
    cached = cache.get(cache_key)
    if cached:
        logger.info(f"Cache HIT for order: {order_id}")
        return cached
    
    table = get_shipping_table()
    
    try:
        response = table.query(
            IndexName='order_id-index',
            KeyConditionExpression='order_id = :oid',
            ExpressionAttributeValues={':oid': order_id}
        )
        
        shipments = response.get('Items', [])
        if not shipments:
            raise HTTPException(
                status_code=404, 
                detail=f"No shipments found for order {order_id}"
            )
        
        # Cache for 30 seconds
        cache.set(cache_key, shipments, ttl=30)
        logger.info(f"Cached shipments for order: {order_id}")
        
        return shipments
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error querying shipments for order {order_id}: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/shipments/track/{tracking_number}", response_model=ShipmentTracking)
def track_shipment(tracking_number: str):
    """Public tracking endpoint - no authentication required"""
    
    # Step 1: Check Redis cache first
    cache_key = f"tracking:{tracking_number}"
    cached = cache.get(cache_key)
    if cached:
        logger.info(f"Cache HIT for tracking: {tracking_number}")
        return cached
    
    # Step 2: Cache MISS - Query DynamoDB
    logger.info(f"Cache MISS for tracking: {tracking_number}")
    table = get_shipping_table()
    
    try:
        response = table.query(
            IndexName='tracking_number-index',
            KeyConditionExpression='tracking_number = :tn',
            ExpressionAttributeValues={':tn': tracking_number}
        )
        
        items = response.get('Items', [])
        if not items:
            raise HTTPException(
                status_code=404, 
                detail="Tracking number not found"
            )
        
        shipment = items[0]
        
        # Step 3: Build tracking response
        tracking_data = {
            'tracking_number': shipment['tracking_number'],
            'current_status': shipment['status'],
            'estimated_delivery': shipment.get('estimated_delivery'),
            'tracking_history': shipment.get('tracking_history', []),
            'is_terminal': ShipmentStateMachine.is_terminal(
                ShipmentStatus(shipment['status'])
            )
        }
        
        # Step 4: Store in Redis cache for 60 seconds
        cache.set(cache_key, tracking_data, ttl=60)
        logger.info(f"Cached tracking: {tracking_number}")
        
        return tracking_data
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error tracking shipment {tracking_number}: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/shipments/user/{user_id}", response_model=List[Shipment])
def get_user_shipments(
    user_id: str, 
    status: Optional[str] = Query(None, description="Filter by status")
):
    """Get all shipments for a user, optionally filtered by status"""
    
    # Cache key includes status filter
    cache_key = f"shipments:user:{user_id}:{status or 'all'}"
    cached = cache.get(cache_key)
    if cached:
        logger.info(f"Cache HIT for user shipments: {user_id}")
        return cached
    
    table = get_shipping_table()
    
    try:
        if status:
            response = table.query(
                IndexName='user_id-index',
                KeyConditionExpression='user_id = :uid AND #status = :status',
                ExpressionAttributeNames={'#status': 'status'},
                ExpressionAttributeValues={
                    ':uid': user_id,
                    ':status': status
                }
            )
        else:
            response = table.query(
                IndexName='user_id-index',
                KeyConditionExpression='user_id = :uid',
                ExpressionAttributeValues={':uid': user_id}
            )
        
        shipments = response.get('Items', [])
        
        # Cache for 30 seconds
        cache.set(cache_key, shipments, ttl=30)
        
        return shipments
        
    except Exception as e:
        logger.error(f"Error getting shipments for user {user_id}: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/shipments", response_model=List[Shipment])
def list_all_shipments(
    status: Optional[str] = Query(None, description="Filter by status"),
    limit: int = Query(50, ge=1, le=100)
):
    """Admin endpoint to list all shipments"""
    table = get_shipping_table()
    
    try:
        if status:
            response = table.scan(
                FilterExpression='#status = :status',
                ExpressionAttributeNames={'#status': 'status'},
                ExpressionAttributeValues={':status': status},
                Limit=limit
            )
        else:
            response = table.scan(Limit=limit)
        
        return response.get('Items', [])
        
    except Exception as e:
        logger.error(f"Error listing shipments: {e}")
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8005)