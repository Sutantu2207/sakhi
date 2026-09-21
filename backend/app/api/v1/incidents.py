from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from backend.app.db.session import get_db
from backend.app.api.deps import get_current_user, get_optional_current_user
from backend.app.models.user import User
from backend.app.models.incident import Incident, IncidentStatus
from backend.app.schemas.incident import IncidentCreate, IncidentOut
from backend.app.services.incident_service import report_incident, get_nearby_incidents

router = APIRouter(prefix="/incidents", tags=["Incidents"])


@router.post("/report", response_model=IncidentOut, status_code=status.HTTP_201_CREATED)
def api_report_incident(
    data: IncidentCreate,
    current_user: Optional[User] = Depends(get_optional_current_user),
    db: Session = Depends(get_db)
):
    return report_incident(db, current_user, data)


@router.get("/nearby", response_model=List[IncidentOut])
def api_get_nearby_incidents(
    latitude: float = Query(..., ge=-90.0, le=90.0),
    longitude: float = Query(..., ge=-180.0, le=180.0),
    radius_km: float = Query(5.0, ge=0.1, le=50.0),
    db: Session = Depends(get_db)
):
    return get_nearby_incidents(db, latitude, longitude, radius_km, include_pending=False)


@router.get("/{incident_id}", response_model=IncidentOut)
def api_get_incident(
    incident_id: str,
    db: Session = Depends(get_db)
):
    incident = db.query(Incident).filter(Incident.id == incident_id).first()
    if not incident:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Incident not found.")
    return incident
