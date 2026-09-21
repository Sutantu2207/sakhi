from datetime import datetime, timezone
from typing import Optional, List
from sqlalchemy.orm import Session
from fastapi import HTTPException, status
from backend.app.models.incident import Incident, IncidentStatus, IncidentCategory, IncidentSeverity
from backend.app.models.user import User
from backend.app.schemas.incident import IncidentCreate, IncidentModeration
from backend.app.services.audit_service import log_action
from backend.app.utils.geo import haversine_distance


def report_incident(db: Session, user: Optional[User], data: IncidentCreate) -> Incident:
    incident = Incident(
        reporter_id=user.id if (user and not data.is_anonymous) else None,
        is_anonymous=data.is_anonymous or (user is None),
        category=data.category,
        severity=data.severity,
        description=data.description,
        incident_time=data.incident_time or datetime.now(timezone.utc),
        latitude=data.latitude,
        longitude=data.longitude,
        status=IncidentStatus.PENDING
    )
    db.add(incident)
    db.commit()
    db.refresh(incident)

    log_action(
        db,
        action="INCIDENT_REPORTED",
        resource_type="INCIDENT",
        resource_id=incident.id,
        user_id=user.id if user else None,
        details=f"Category: {incident.category.value}, Lat: {incident.latitude}, Lon: {incident.longitude}"
    )
    return incident


def moderate_incident(db: Session, moderator: User, incident_id: str, data: IncidentModeration) -> Incident:
    incident = db.query(Incident).filter(Incident.id == incident_id).first()
    if not incident:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Incident not found.")

    incident.status = data.status
    if data.moderator_notes:
        incident.moderator_notes = data.moderator_notes
    db.commit()
    db.refresh(incident)

    log_action(
        db,
        action=f"INCIDENT_MODERATED_{data.status.value}",
        resource_type="INCIDENT",
        resource_id=incident.id,
        user_id=moderator.id,
        details=data.moderator_notes
    )
    return incident


def get_nearby_incidents(
    db: Session,
    latitude: float,
    longitude: float,
    radius_km: float = 5.0,
    include_pending: bool = False
) -> List[Incident]:
    # Query incidents
    query = db.query(Incident)
    if not include_pending:
        query = query.filter(Incident.status == IncidentStatus.VERIFIED)

    all_incidents = query.all()
    filtered = []
    for inc in all_incidents:
        dist = haversine_distance(latitude, longitude, inc.latitude, inc.longitude)
        if dist <= radius_km:
            filtered.append(inc)

    return filtered
