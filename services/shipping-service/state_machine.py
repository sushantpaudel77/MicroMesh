from typing import List, Dict, Set
from models import ShipmentStatus

class ShipmentStateMachine:
    """Manages valid state transitions for shipments"""
    
    # Define all valid transitions
    TRANSITIONS: Dict[ShipmentStatus, List[ShipmentStatus]] = {
        ShipmentStatus.PENDING: [
            ShipmentStatus.LABEL_CREATED,
            ShipmentStatus.CANCELLED
        ],
        ShipmentStatus.LABEL_CREATED: [
            ShipmentStatus.PICKUP_SCHEDULED,
            ShipmentStatus.CANCELLED
        ],
        ShipmentStatus.PICKUP_SCHEDULED: [
            ShipmentStatus.PICKED_UP,
            ShipmentStatus.CANCELLED
        ],
        ShipmentStatus.PICKED_UP: [
            ShipmentStatus.IN_TRANSIT,
            ShipmentStatus.LOST,
            ShipmentStatus.DAMAGED
        ],
        ShipmentStatus.IN_TRANSIT: [
            ShipmentStatus.ARRIVED_AT_HUB,
            ShipmentStatus.OUT_FOR_DELIVERY,
            ShipmentStatus.LOST,
            ShipmentStatus.DAMAGED
        ],
        ShipmentStatus.ARRIVED_AT_HUB: [
            ShipmentStatus.IN_TRANSIT,
            ShipmentStatus.OUT_FOR_DELIVERY,
            ShipmentStatus.LOST,
            ShipmentStatus.DAMAGED
        ],
        ShipmentStatus.OUT_FOR_DELIVERY: [
            ShipmentStatus.DELIVERED,
            ShipmentStatus.DELIVERY_FAILED,
            ShipmentStatus.LOST
        ],
        ShipmentStatus.DELIVERED: [
            ShipmentStatus.RETURN_INITIATED
        ],
        ShipmentStatus.DELIVERY_FAILED: [
            ShipmentStatus.RETURN_INITIATED,
            ShipmentStatus.OUT_FOR_DELIVERY
        ],
        ShipmentStatus.RETURN_INITIATED: [
            ShipmentStatus.RETURN_IN_TRANSIT,
            ShipmentStatus.CANCELLED
        ],
        ShipmentStatus.RETURN_IN_TRANSIT: [
            ShipmentStatus.RETURNED,
            ShipmentStatus.LOST
        ],
        ShipmentStatus.RETURNED: [],  # Terminal state
        ShipmentStatus.LOST: [],       # Terminal state
        ShipmentStatus.DAMAGED: [      # Terminal state
            ShipmentStatus.RETURN_INITIATED
        ],
        ShipmentStatus.CANCELLED: []   # Terminal state
    }
    
    # States that require location
    LOCATION_REQUIRED: Set[ShipmentStatus] = {
        ShipmentStatus.PICKED_UP,
        ShipmentStatus.IN_TRANSIT,
        ShipmentStatus.ARRIVED_AT_HUB,
        ShipmentStatus.OUT_FOR_DELIVERY,
        ShipmentStatus.DELIVERED,
        ShipmentStatus.DELIVERY_FAILED,
        ShipmentStatus.RETURN_IN_TRANSIT,
        ShipmentStatus.RETURNED
    }
    
    # Terminal states
    TERMINAL_STATES: Set[ShipmentStatus] = {
        ShipmentStatus.DELIVERED,
        ShipmentStatus.RETURNED,
        ShipmentStatus.LOST,
        ShipmentStatus.CANCELLED
    }
    
    @classmethod
    def can_transition(cls, from_status: ShipmentStatus, to_status: ShipmentStatus) -> bool:
        """Check if transition is valid"""
        if from_status not in cls.TRANSITIONS:
            return False
        return to_status in cls.TRANSITIONS[from_status]
    
    @classmethod
    def requires_location(cls, status: ShipmentStatus) -> bool:
        """Check if status requires location update"""
        return status in cls.LOCATION_REQUIRED
    
    @classmethod
    def is_terminal(cls, status: ShipmentStatus) -> bool:
        """Check if status is terminal"""
        return status in cls.TERMINAL_STATES
    
    @classmethod
    def get_allowed_transitions(cls, current_status: ShipmentStatus) -> List[ShipmentStatus]:
        """Get all valid next states"""
        return cls.TRANSITIONS.get(current_status, [])