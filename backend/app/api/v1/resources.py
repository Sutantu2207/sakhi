from typing import List, Optional
from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from backend.app.db.session import get_db
from backend.app.models.resource import ResourceCategory, SupportCategory
from backend.app.schemas.resource import EmergencyResourceOut, SupportResourceOut
from backend.app.services.resource_service import get_nearby_emergency_resources, get_support_resources

router = APIRouter(prefix="/resources", tags=["Emergency & Support Resources"])


@router.get("/emergency/nearby", response_model=List[EmergencyResourceOut])
def api_nearby_emergency_resources(
    latitude: float = Query(..., ge=-90.0, le=90.0),
    longitude: float = Query(..., ge=-180.0, le=180.0),
    radius_km: float = Query(10.0, ge=0.5, le=50.0),
    category: Optional[ResourceCategory] = Query(None),
    db: Session = Depends(get_db)
):
    return get_nearby_emergency_resources(db, latitude, longitude, radius_km, category)


@router.get("/support", response_model=List[SupportResourceOut])
def api_get_support_resources(
    category: Optional[SupportCategory] = Query(None),
    db: Session = Depends(get_db)
):
    return get_support_resources(db, category)
