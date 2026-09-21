import math
from typing import Tuple


def haversine_distance(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """
    Calculate the great circle distance in kilometers between two points
    on the earth (specified in decimal degrees).
    """
    # Convert decimal degrees to radians
    lat1, lon1, lat2, lon2 = map(math.radians, [lat1, lon1, lat2, lon2])

    # Haversine formula
    dlat = lat2 - lat1
    dlon = lon2 - lon1
    a = math.sin(dlat / 2)**2 + math.cos(lat1) * math.cos(lat2) * math.sin(dlon / 2)**2
    c = 2 * math.asin(math.sqrt(a))
    r = 6371.0  # Radius of earth in kilometers
    return round(c * r, 3)


def is_within_radius(lat1: float, lon1: float, lat2: float, lon2: float, radius_km: float) -> bool:
    return haversine_distance(lat1, lon1, lat2, lon2) <= radius_km


def get_approx_cell(lat: float, lon: float, precision: int = 2) -> str:
    """
    Privacy-preserving spatial grid cell key.
    Precision 2 means approximately 1.1km grid cell.
    Never exposes exact coordinates.
    """
    return f"{round(lat, precision)}:{round(lon, precision)}"
