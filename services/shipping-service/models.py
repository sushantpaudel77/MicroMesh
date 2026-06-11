from pydantic import BaseModel
from typing import List, Optional, Dict, Any
from enum import Enum

class ShipmentStatus(str, Enum):
    PENDING = "PENDING"
    LABEL_CREATED = "LABEL_CREATED"
    PICKUP_SCHEDULED = "PICKUP_SCHEDULED"
    PICKED_UP = "PICKED_UP"
    IN_TRANSIT = "IN_TRANSIT"
    ARRIVED_AT_HUB = "ARRIVED_AT_HUB"
    OUT_FOR_DELIVERY = "OUT_FOR_DELIVERY"
    DELIVERED = "DELIVERED"
    DELIVERY_FAILED = "DELIVERY_FAILED"
    RETURN_INITIATED = "RETURN_INITIATED"
    RETURN_IN_TRANSIT = "RETURN_IN_TRANSIT"
    RETURNED = "RETURNED"
    LOST = "LOST"
    DAMAGED = "DAMAGED"
    CANCELLED = "CANCELLED"

class TrackingEvent(BaseModel):
    status: ShipmentStatus
    location: str
    time: str
    description: Optional[str] = None

class PackageDetails(BaseModel):
    weight: Optional[str] = None
    dimensions: Optional[str] = None
    description: Optional[str] = None
    items: Optional[List[str]] = []

class ShipmentCreate(BaseModel):
    order_id: int
    user_id: str
    user_email: str
    origin_address: str = "Main Warehouse, 123 Storage St"
    destination_address: Optional[str] = None
    package_details: Optional[Dict[str, Any]] = None
    carrier: Optional[str] = None
    shipping_method: Optional[str] = "Standard"

class ShipmentStatusUpdate(BaseModel):
    status: ShipmentStatus
    location: Optional[str] = None
    description: Optional[str] = None
    carrier_tracking_id: Optional[str] = None

class Shipment(BaseModel):
    shipment_id: str
    order_id: int
    user_id: str
    user_email: str
    status: ShipmentStatus
    tracking_number: str
    carrier: Optional[str] = None
    shipping_method: Optional[str] = "Standard"
    origin_address: str
    destination_address: Optional[str] = None
    package_details: Optional[Dict[str, Any]] = None
    tracking_history: List[TrackingEvent] = []
    estimated_delivery: Optional[str] = None
    carrier_tracking_id: Optional[str] = None
    created_at: str
    updated_at: str

class ShipmentTracking(BaseModel):
    tracking_number: str
    current_status: ShipmentStatus
    estimated_delivery: Optional[str] = None
    tracking_history: List[TrackingEvent] = []
    is_terminal: bool