from typing import Dict, Any
from sqlalchemy.orm import Session
from backend.app.models.user import User
from backend.app.services.cache_service import cache_service
from backend.app.utils.geo import get_approx_cell


def register_presence(user: User, latitude: float, longitude: float) -> Dict[str, Any]:
    if not user.safety_network_opt_in:
        return {
            "opted_in": False,
            "nearby_participants_count": 0,
            "approximate_cell": "Disabled",
            "message": "Safety Network is currently disabled in your privacy settings."
        }

    # Store presence with 10-minute TTL (600s)
    cache_service.set_presence(user.id, latitude, longitude, ttl=600)

    # Get approximate nearby count within 3km
    count = cache_service.get_nearby_presence_count(latitude, longitude, radius_km=3.0)
    approx_cell = get_approx_cell(latitude, longitude, precision=2)

    return {
        "opted_in": True,
        "nearby_participants_count": max(1, count),  # includes self
        "approximate_cell": approx_cell,
        "message": f"Connected to Sakhi community network cell ({approx_cell}). Zero personal data shared."
    }


def leave_network(user: User):
    cache_service.remove_presence(user.id)
