from datetime import datetime, timezone
from typing import Optional, List
from sqlalchemy.orm import Session
from fastapi import HTTPException, status
from backend.app.models.sos import SOSEvent, SOSStatus
from backend.app.models.contact import EmergencyContact
from backend.app.models.user import User
from backend.app.schemas.sos import SOSTrigger, SOSCancel, SOSResolve
from backend.app.services.cache_service import cache_service
from backend.app.services.audit_service import log_action


def trigger_sos(db: Session, user: User, data: SOSTrigger) -> SOSEvent:
    # Check if there's already an active SOS for this user
    existing_sos = db.query(SOSEvent).filter(
        SOSEvent.user_id == user.id,
        SOSEvent.status.in_([SOSStatus.CREATED, SOSStatus.ACTIVE, SOSStatus.ACKNOWLEDGED])
    ).first()

    if existing_sos:
        # Update coordinates of active SOS
        existing_sos.latitude = data.latitude
        existing_sos.longitude = data.longitude
        if data.address_approx:
            existing_sos.address_approx = data.address_approx
        db.commit()
        db.refresh(existing_sos)
        return existing_sos

    # Query emergency contacts configured for SOS
    contacts = db.query(EmergencyContact).filter(
        EmergencyContact.user_id == user.id,
        EmergencyContact.notify_on_sos == True
    ).all()

    contacts_count = len(contacts)
    # Record notification attempt
    notification_status = "SENT" if contacts_count > 0 else "NO_CONTACTS_CONFIGURED"

    sos = SOSEvent(
        user_id=user.id,
        status=SOSStatus.ACTIVE,
        latitude=data.latitude,
        longitude=data.longitude,
        address_approx=data.address_approx or "GPS Coordinates Captured",
        triggered_at=datetime.now(timezone.utc),
        contacts_notified_count=contacts_count,
        notification_status=notification_status
    )
    db.add(sos)
    db.commit()
    db.refresh(sos)

    # Cache active SOS in Redis
    cache_service.set_active_sos(sos.id, {
        "sos_id": sos.id,
        "user_id": user.id,
        "user_name": user.full_name,
        "user_phone": user.phone,
        "latitude": data.latitude,
        "longitude": data.longitude,
        "triggered_at": sos.triggered_at.isoformat(),
        "status": SOSStatus.ACTIVE.value
    })

    log_action(
        db,
        action="SOS_TRIGGERED",
        resource_type="SOS",
        resource_id=sos.id,
        user_id=user.id,
        details=f"Lat: {data.latitude}, Lon: {data.longitude}, Contacts Notified: {contacts_count}"
    )

    return sos


def cancel_sos(db: Session, user: User, sos_id: str, data: Optional[SOSCancel] = None) -> SOSEvent:
    sos = db.query(SOSEvent).filter(SOSEvent.id == sos_id, SOSEvent.user_id == user.id).first()
    if not sos:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="SOS event not found.")

    if sos.status in [SOSStatus.RESOLVED, SOSStatus.CANCELLED]:
        return sos

    sos.status = SOSStatus.CANCELLED
    sos.resolved_at = datetime.now(timezone.utc)
    sos.admin_notes = f"User cancelled: {data.reason if data else 'No reason specified'}"
    db.commit()
    db.refresh(sos)

    cache_service.delete_active_sos(sos.id)
    log_action(db, action="SOS_CANCELLED", resource_type="SOS", resource_id=sos.id, user_id=user.id)
    return sos


def resolve_sos_by_admin(db: Session, admin_user: User, sos_id: str, data: SOSResolve) -> SOSEvent:
    sos = db.query(SOSEvent).filter(SOSEvent.id == sos_id).first()
    if not sos:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="SOS event not found.")

    sos.status = SOSStatus.RESOLVED
    sos.resolved_at = datetime.now(timezone.utc)
    sos.responder_id = admin_user.id
    if data.admin_notes:
        sos.admin_notes = data.admin_notes
    db.commit()
    db.refresh(sos)

    cache_service.delete_active_sos(sos.id)
    log_action(
        db,
        action="SOS_RESOLVED_BY_ADMIN",
        resource_type="SOS",
        resource_id=sos.id,
        user_id=admin_user.id,
        details=f"Resolved by {admin_user.full_name}: {data.admin_notes or 'No notes'}"
    )
    return sos


def acknowledge_sos_by_admin(db: Session, admin_user: User, sos_id: str) -> SOSEvent:
    sos = db.query(SOSEvent).filter(SOSEvent.id == sos_id).first()
    if not sos:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="SOS event not found.")

    sos.status = SOSStatus.ACKNOWLEDGED
    sos.responder_id = admin_user.id
    db.commit()
    db.refresh(sos)

    log_action(
        db,
        action="SOS_ACKNOWLEDGED_BY_ADMIN",
        resource_type="SOS",
        resource_id=sos.id,
        user_id=admin_user.id
    )
    return sos


def get_active_sos_events(db: Session) -> List[SOSEvent]:
    return db.query(SOSEvent).filter(
        SOSEvent.status.in_([SOSStatus.CREATED, SOSStatus.ACTIVE, SOSStatus.ACKNOWLEDGED])
    ).order_by(SOSEvent.triggered_at.desc()).all()
