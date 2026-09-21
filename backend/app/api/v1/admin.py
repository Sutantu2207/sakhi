from datetime import datetime, timezone, timedelta
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from sqlalchemy import func
from backend.app.db.session import get_db
from backend.app.api.deps import get_current_admin, get_current_moderator
from backend.app.models.user import User, UserRole
from backend.app.models.journey import Journey, JourneyStatus
from backend.app.models.sos import SOSEvent, SOSStatus
from backend.app.models.incident import Incident, IncidentStatus, IncidentCategory
from backend.app.models.resource import EmergencyResource, SupportResource
from backend.app.models.audit import AuditLog
from backend.app.schemas.incident import IncidentModeration, IncidentOut
from backend.app.schemas.sos import SOSResolve, SOSOut
from backend.app.schemas.resource import (
    EmergencyResourceCreate, EmergencyResourceOut,
    SupportResourceCreate, SupportResourceOut
)
from backend.app.services.incident_service import moderate_incident
from backend.app.services.sos_service import acknowledge_sos_by_admin, resolve_sos_by_admin
from backend.app.services.resource_service import create_emergency_resource, create_support_resource

router = APIRouter(prefix="/admin", tags=["Administrative Portal"])


@router.get("/overview")
def get_admin_overview(
    current_user: User = Depends(get_current_admin),
    db: Session = Depends(get_db)
):
    now = datetime.now(timezone.utc)
    today_start = datetime(now.year, now.month, now.day, tzinfo=timezone.utc)

    active_journeys_count = db.query(Journey).filter(
        Journey.status.in_([JourneyStatus.STARTED, JourneyStatus.ACTIVE])
    ).count()

    active_sos_count = db.query(SOSEvent).filter(
        SOSEvent.status.in_([SOSStatus.CREATED, SOSStatus.ACTIVE, SOSStatus.ACKNOWLEDGED])
    ).count()

    incidents_today_count = db.query(Incident).filter(
        Incident.created_at >= today_start
    ).count()

    total_incidents_count = db.query(Incident).count()
    resolved_incidents_count = db.query(Incident).filter(
        Incident.status == IncidentStatus.RESOLVED
    ).count()

    pending_moderation_count = db.query(Incident).filter(
        Incident.status == IncidentStatus.PENDING
    ).count()

    total_users_count = db.query(User).filter(User.role == UserRole.USER).count()
    verified_resources_count = db.query(EmergencyResource).filter(
        EmergencyResource.is_verified == True
    ).count()

    # Category breakdown
    cat_counts = db.query(
        Incident.category, func.count(Incident.id)
    ).group_by(Incident.category).all()
    categories_breakdown = {c[0].value: c[1] for c in cat_counts}

    # Status breakdown
    status_counts = db.query(
        Incident.status, func.count(Incident.id)
    ).group_by(Incident.status).all()
    status_breakdown = {s[0].value: s[1] for s in status_counts}

    return {
        "active_journeys": active_journeys_count,
        "active_sos": active_sos_count,
        "incidents_today": incidents_today_count,
        "total_incidents": total_incidents_count,
        "resolved_incidents": resolved_incidents_count,
        "pending_moderation": pending_moderation_count,
        "total_users": total_users_count,
        "verified_resources": verified_resources_count,
        "categories_breakdown": categories_breakdown,
        "status_breakdown": status_breakdown,
        "system_status": "OPERATIONAL"
    }


@router.get("/incidents", response_model=List[IncidentOut])
def list_all_incidents(
    status: Optional[IncidentStatus] = None,
    category: Optional[IncidentCategory] = None,
    current_user: User = Depends(get_current_moderator),
    db: Session = Depends(get_db)
):
    query = db.query(Incident)
    if status:
        query = query.filter(Incident.status == status)
    if category:
        query = query.filter(Incident.category == category)
    return query.order_by(Incident.created_at.desc()).all()


@router.put("/incidents/{incident_id}/moderate", response_model=IncidentOut)
def api_moderate_incident(
    incident_id: str,
    data: IncidentModeration,
    current_user: User = Depends(get_current_moderator),
    db: Session = Depends(get_db)
):
    return moderate_incident(db, current_user, incident_id, data)


@router.get("/sos", response_model=List[SOSOut])
def list_sos_events(
    status: Optional[SOSStatus] = None,
    current_user: User = Depends(get_current_admin),
    db: Session = Depends(get_db)
):
    query = db.query(SOSEvent)
    if status:
        query = query.filter(SOSEvent.status == status)
    return query.order_by(SOSEvent.triggered_at.desc()).all()


@router.put("/sos/{sos_id}/acknowledge", response_model=SOSOut)
def api_acknowledge_sos(
    sos_id: str,
    current_user: User = Depends(get_current_admin),
    db: Session = Depends(get_db)
):
    return acknowledge_sos_by_admin(db, current_user, sos_id)


@router.put("/sos/{sos_id}/resolve", response_model=SOSOut)
def api_resolve_sos(
    sos_id: str,
    data: SOSResolve,
    current_user: User = Depends(get_current_admin),
    db: Session = Depends(get_db)
):
    return resolve_sos_by_admin(db, current_user, sos_id, data)


@router.get("/resources/emergency", response_model=List[EmergencyResourceOut])
def list_emergency_resources(
    current_user: User = Depends(get_current_admin),
    db: Session = Depends(get_db)
):
    return db.query(EmergencyResource).order_by(EmergencyResource.created_at.desc()).all()


@router.post("/resources/emergency", response_model=EmergencyResourceOut, status_code=status.HTTP_201_CREATED)
def add_emergency_resource(
    data: EmergencyResourceCreate,
    current_user: User = Depends(get_current_admin),
    db: Session = Depends(get_db)
):
    return create_emergency_resource(db, data)


@router.delete("/resources/emergency/{resource_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_emergency_resource(
    resource_id: str,
    current_user: User = Depends(get_current_admin),
    db: Session = Depends(get_db)
):
    res = db.query(EmergencyResource).filter(EmergencyResource.id == resource_id).first()
    if not res:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Resource not found.")
    db.delete(res)
    db.commit()
    return None


@router.get("/resources/support", response_model=List[SupportResourceOut])
def list_support_resources(
    current_user: User = Depends(get_current_admin),
    db: Session = Depends(get_db)
):
    return db.query(SupportResource).order_by(SupportResource.created_at.desc()).all()


@router.post("/resources/support", response_model=SupportResourceOut, status_code=status.HTTP_201_CREATED)
def add_support_resource(
    data: SupportResourceCreate,
    current_user: User = Depends(get_current_admin),
    db: Session = Depends(get_db)
):
    return create_support_resource(db, data)


@router.get("/audit-logs")
def list_audit_logs(
    limit: int = Query(50, ge=1, le=200),
    current_user: User = Depends(get_current_admin),
    db: Session = Depends(get_db)
):
    logs = db.query(AuditLog).order_by(AuditLog.timestamp.desc()).limit(limit).all()
    return [
        {
            "id": l.id,
            "action": l.action,
            "resource_type": l.resource_type,
            "resource_id": l.resource_id,
            "user_id": l.user_id,
            "details": l.details,
            "ip_address": l.ip_address,
            "timestamp": l.timestamp
        }
        for l in logs
    ]
