"""
AWS Lambda Function - Order Shipping Processor
Triggered by SQS when orders are placed
Creates shipments via Shipping Service API
"""

import json
import os
import logging
from urllib.request import Request, urlopen
from urllib.error import HTTPError, URLError

# Configuration
logger = logging.getLogger()
logger.setLevel(logging.INFO)

SHIPPING_SERVICE_URL = os.environ.get('SHIPPING_SERVICE_URL', 'http://localhost:8005')

# Lambda Handler
def lambda_handler(event, context):
    """
    Process SQS messages containing order events
    Creates shipments by calling the Shipping Service API
    """
    logger.info(f"Processing {len(event.get('Records', []))} SQS messages")
    
    results = {
        'processed': 0,
        'failed': 0,
        'shipment_ids': []
    }
    
    for record in event.get('Records', []):
        try:
            # Parse SQS message
            body = json.loads(record['body'])
            
            # Handle SNS-wrapped messages (SNS → SQS)
            if 'Message' in body:
                message = json.loads(body['Message'])
            else:
                message = body
            
            # Extract order data
            order = message.get('order', message)
            order_id = order.get('order_id')
            
            if not order_id:
                logger.error("No order_id in message, skipping")
                results['failed'] += 1
                continue
            
            logger.info(f"Creating shipment for order #{order_id}")
            
            # Build shipment payload
            shipment = build_shipment_payload(order)
            
            # Call Shipping Service
            shipment_id = create_shipment(shipment)
            
            if shipment_id:
                results['processed'] += 1
                results['shipment_ids'].append(shipment_id)
                logger.info(f"Shipment {shipment_id} created for order #{order_id}")
            else:
                results['failed'] += 1
                logger.error(f"Failed to create shipment for order #{order_id}")
                
        except Exception as e:
            logger.error(f"Error processing message: {str(e)}")
            results['failed'] += 1
    
    logger.info(f"Complete - Processed: {results['processed']}, Failed: {results['failed']}")
    
    return {
        'statusCode': 200,
        'body': json.dumps(results)
    }

# Helper Functions
def build_shipment_payload(order):
    """Build shipment creation payload from order data"""
    
    return {
        'order_id': order.get('order_id'),
        'user_id': str(order.get('user_id', 'unknown')),
        'user_email': order.get('user_email', 'unknown@example.com'),
        'origin_address': get_origin_address(order),
        'destination_address': get_destination_address(order),
        'package_details': get_package_details(order),
        'carrier': order.get('carrier', 'DefaultCarrier'),
        'shipping_method': order.get('shipping_method', 'Standard')
    }


def create_shipment(payload):
    """Call Shipping Service API to create shipment"""
    try:
        url = f"{SHIPPING_SERVICE_URL}/shipments"
        data = json.dumps(payload).encode('utf-8')
        
        request = Request(
            url,
            data=data,
            headers={
                'Content-Type': 'application/json',
                'Accept': 'application/json'
            },
            method='POST'
        )
        
        with urlopen(request, timeout=30) as response:
            result = json.loads(response.read().decode('utf-8'))
            return result.get('shipment_id')
            
    except HTTPError as e:
        error_body = e.read().decode('utf-8') if e.fp else str(e)
        logger.error(f"HTTP {e.code}: {error_body}")
        return None
    except URLError as e:
        logger.error(f"Connection failed: {e.reason}")
        return None
    except Exception as e:
        logger.error(f"Unexpected error: {str(e)}")
        return None


def get_origin_address(order):
    """Get origin shipping address"""
    address = order.get('shipping_address', {})
    if address:
        parts = [
            address.get('full_name', ''),
            address.get('address_line1', ''),
            address.get('city', ''),
            address.get('state', ''),
            address.get('postal_code', ''),
            address.get('country', '')
        ]
        return ', '.join(filter(None, parts))
    return 'Main Warehouse, 123 Storage St, Default City, 00000'


def get_destination_address(order):
    """Get destination address (same as shipping for now)"""
    return get_origin_address(order)


def get_package_details(order):
    """Extract package details from order items"""
    items = order.get('items', [])
    
    return {
        'weight': calculate_weight(items),
        'dimensions': '30x20x15 cm',
        'description': f"Order containing {len(items)} item(s)",
        'items_count': len(items),
        'items': [item.get('product_id', '') for item in items]
    }


def calculate_weight(items):
    """Calculate estimated package weight"""
    total_items = sum(item.get('quantity', 1) for item in items)
    estimated_kg = total_items * 0.5
    return f"{estimated_kg:.1f} kg"