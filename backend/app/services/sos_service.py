import secrets
from datetime import datetime, timezone, timedelta
from typing import Optional, List
from sqlalchemy.orm import Session
from fastapi import HTTPException, status
from backend.app.models.sos import SOSEvent, SOSStatus
from backend.app.models.contact import EmergencyContact
from backend.app.models.user import User
from backend.app.models.journey import Journey, JourneyStatus, JourneyShare
from backend.app.schemas.sos import SOSTrigger, SOSCancel, SOSResolve, SOSOut
from backend.app.services.cache_service import cache_service
from backend.app.services.audit_service import log_action


def _format_sos_out(sos: SOSEvent, user: Optional[User] = None, journey: Optional[Journey] = None) -> SOSOut:
    """Helper to convert SOSEvent to SOSOut with enriched victim and journey metadata."""
    u_name = user.full_name if user else (sos.user.full_name if sos.user else None)
    u_phone = user.phone if user else (sos.user.phone if sos.user else None)
    j_dest = journey.destination_name if journey else (sos.journey.destination_name if sos.journey else None)

    return SOSOut(
        id=sos.id,
        user_id=sos.user_id,
        status=sos.status,
        latitude=sos.latitude,
        longitude=sos.longitude,
        accuracy_meters=sos.accuracy_meters or 10.0,
        address_approx=sos.address_approx,
        triggered_at=sos.triggered_at,
        resolved_at=sos.resolved_at,
        contacts_notified_count=sos.contacts_notified_count,
        notification_status=sos.notification_status,
        admin_notes=sos.admin_notes,
        responder_id=sos.responder_id,
        journey_id=sos.journey_id,
        share_token=sos.share_token,
        user_name=u_name,
        user_phone=u_phone,
        destination_name=j_dest
    )


def trigger_sos(db: Session, user: User, data: SOSTrigger) -> SOSEvent:
    # Check if there's already an active SOS for this user
    existing_sos = db.query(SOSEvent).filter(
        SOSEvent.user_id == user.id,
        SOSEvent.status.in_([SOSStatus.CREATED, SOSStatus.ACTIVE, SOSStatus.ACKNOWLEDGED])
    ).first()

    if existing_sos:
        # Update coordinates and accuracy of existing active SOS
        existing_sos.latitude = data.latitude
        existing_sos.longitude = data.longitude
        existing_sos.accuracy_meters = data.accuracy_meters or existing_sos.accuracy_meters or 10.0
        if data.address_approx:
            existing_sos.address_approx = data.address_approx
        db.commit()
        db.refresh(existing_sos)

        # Update cache
        cache_service.set_active_sos(existing_sos.id, {
            "sos_id": existing_sos.id,
            "user_id": user.id,
            "user_name": user.full_name,
            "user_phone": user.phone,
            "latitude": existing_sos.latitude,
            "longitude": existing_sos.longitude,
            "accuracy_meters": existing_sos.accuracy_meters,
            "triggered_at": existing_sos.triggered_at.isoformat(),
            "status": existing_sos.status.value,
            "journey_id": existing_sos.journey_id,
            "share_token": existing_sos.share_token
        })
        return existing_sos

    # Detect active journey for this user if available
    active_journey = None
    if data.journey_id:
        active_journey = db.query(Journey).filter(Journey.id == data.journey_id, Journey.user_id == user.id).first()
    if not active_journey:
        active_journey = db.query(Journey).filter(
            Journey.user_id == user.id,
            Journey.status.in_([JourneyStatus.STARTED, JourneyStatus.ACTIVE])
        ).order_by(Journey.start_time.desc()).first()

    journey_id = active_journey.id if active_journey else None

    # Generate or retrieve a secure emergency temporary tracking token
    share_token = None
    if active_journey:
        active_share = db.query(JourneyShare).filter(
            JourneyShare.journey_id == active_journey.id,
            JourneyShare.is_revoked == False,
            JourneyShare.expires_at > datetime.now(timezone.utc)
        ).first()
        if active_share:
            share_token = active_share.share_token
        else:
            share_token = secrets.token_urlsafe(32)
            new_share = JourneyShare(
                journey_id=active_journey.id,
                share_token=share_token,
                expires_at=datetime.now(timezone.utc) + timedelta(hours=4)
            )
            db.add(new_share)

    # Query emergency contacts configured for SOS alerts
    contacts = db.query(EmergencyContact).filter(
        EmergencyContact.user_id == user.id,
        EmergencyContact.notify_on_sos == True
    ).all()

    contacts_count = len(contacts)
    notification_status = "SENT" if contacts_count > 0 else "NO_CONTACTS_CONFIGURED"

    sos = SOSEvent(
        user_id=user.id,
        status=SOSStatus.ACTIVE,
        latitude=data.latitude,
        longitude=data.longitude,
        accuracy_meters=data.accuracy_meters or 10.0,
        address_approx=data.address_approx or "GPS Coordinates Captured",
        triggered_at=datetime.now(timezone.utc),
        contacts_notified_count=contacts_count,
        notification_status=notification_status,
        journey_id=journey_id,
        share_token=share_token
    )
    db.add(sos)
    db.commit()
    db.refresh(sos)

    # Cache active SOS in Redis / memory presence layer
    cache_service.set_active_sos(sos.id, {
        "sos_id": sos.id,
        "user_id": user.id,
        "user_name": user.full_name,
        "user_phone": user.phone,
        "latitude": data.latitude,
        "longitude": data.longitude,
        "accuracy_meters": sos.accuracy_meters,
        "triggered_at": sos.triggered_at.isoformat(),
        "status": SOSStatus.ACTIVE.value,
        "journey_id": journey_id,
        "destination_name": active_journey.destination_name if active_journey else None,
        "share_token": share_token
    })

    # Structured audit logging
    log_action(
        db,
        action="SOS_TRIGGERED",
        resource_type="SOS",
        resource_id=sos.id,
        user_id=user.id,
        details=f"Lat: {data.latitude}, Lon: {data.longitude}, Acc: {sos.accuracy_meters}m, Contacts Notified: {contacts_count}, Journey: {journey_id or 'None'}"
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

    # Update cache
    cache_service.set_active_sos(sos.id, {
        "sos_id": sos.id,
        "user_id": sos.user_id,
        "latitude": sos.latitude,
        "longitude": sos.longitude,
        "status": SOSStatus.ACKNOWLEDGED.value,
        "responder_id": admin_user.id,
        "responder_name": admin_user.full_name
    })

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
