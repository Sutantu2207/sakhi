from datetime import datetime, timezone, timedelta
from typing import Optional, List
from sqlalchemy.orm import Session
from fastapi import HTTPException, status
from backend.app.models.journey import Journey, JourneyLocation, JourneyShare, JourneyStatus
from backend.app.models.user import User
from backend.app.schemas.journey import JourneyStart, JourneyLocationPing, JourneyEnd, JourneyShareCreate
from backend.app.core.security import generate_secure_token
from backend.app.services.cache_service import cache_service
from backend.app.services.audit_service import log_action
from backend.app.utils.geo import haversine_distance


def start_journey(db: Session, user: User, data: JourneyStart) -> Journey:
    # Mark any previous ACTIVE or STARTED journeys of this user as COMPLETED or CANCELLED
    active_journeys = db.query(Journey).filter(
        Journey.user_id == user.id,
        Journey.status.in_([JourneyStatus.STARTED, JourneyStatus.ACTIVE])
    ).all()
    for aj in active_journeys:
        aj.status = JourneyStatus.COMPLETED
        aj.end_time = datetime.now(timezone.utc)
        cache_service.delete_active_journey(aj.id)

    journey = Journey(
        user_id=user.id,
        status=JourneyStatus.ACTIVE,
        destination_name=data.destination_name,
        start_lat=data.start_lat,
        start_lon=data.start_lon,
        current_lat=data.start_lat,
        current_lon=data.start_lon,
        destination_lat=data.destination_lat,
        destination_lon=data.destination_lon,
        start_time=datetime.now(timezone.utc),
        total_distance_km=0.0
    )
    db.add(journey)
    db.commit()
    db.refresh(journey)

    # Initial location record
    loc = JourneyLocation(
        journey_id=journey.id,
        latitude=data.start_lat,
        longitude=data.start_lon,
        timestamp=datetime.now(timezone.utc)
    )
    db.add(loc)
    db.commit()

    # Cache state in Redis
    cache_service.set_active_journey(journey.id, {
        "journey_id": journey.id,
        "user_id": user.id,
        "current_lat": data.start_lat,
        "current_lon": data.start_lon,
        "status": JourneyStatus.ACTIVE.value,
        "start_time": journey.start_time.isoformat(),
        "total_distance_km": 0.0
    })

    log_action(db, action="JOURNEY_STARTED", resource_type="JOURNEY", resource_id=journey.id, user_id=user.id)
    return journey


def record_location_ping(db: Session, user: User, journey_id: str, data: JourneyLocationPing) -> Journey:
    journey = db.query(Journey).filter(Journey.id == journey_id, Journey.user_id == user.id).first()
    if not journey:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Journey not found.")

    if journey.status not in [JourneyStatus.STARTED, JourneyStatus.ACTIVE]:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Journey is no longer active.")

    # Calculate distance increment
    if journey.current_lat is not None and journey.current_lon is not None:
        delta_dist = haversine_distance(journey.current_lat, journey.current_lon, data.latitude, data.longitude)
        journey.total_distance_km = round(journey.total_distance_km + delta_dist, 3)

    journey.current_lat = data.latitude
    journey.current_lon = data.longitude
    journey.status = JourneyStatus.ACTIVE

    loc = JourneyLocation(
        journey_id=journey.id,
        latitude=data.latitude,
        longitude=data.longitude,
        speed=data.speed,
        accuracy=data.accuracy,
        timestamp=datetime.now(timezone.utc)
    )
    db.add(loc)
    db.commit()
    db.refresh(journey)

    # Update cache
    cache_service.set_active_journey(journey.id, {
        "journey_id": journey.id,
        "user_id": user.id,
        "current_lat": data.latitude,
        "current_lon": data.longitude,
        "status": journey.status.value,
        "start_time": journey.start_time.isoformat(),
        "total_distance_km": journey.total_distance_km
    })

    return journey


def end_journey(db: Session, user: User, journey_id: str, data: Optional[JourneyEnd] = None) -> Journey:
    journey = db.query(Journey).filter(Journey.id == journey_id, Journey.user_id == user.id).first()
    if not journey:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Journey not found.")

    if data and data.final_lat is not None and data.final_lon is not None:
        if journey.current_lat is not None and journey.current_lon is not None:
            delta = haversine_distance(journey.current_lat, journey.current_lon, data.final_lat, data.final_lon)
            journey.total_distance_km = round(journey.total_distance_km + delta, 3)
        journey.current_lat = data.final_lat
        journey.current_lon = data.final_lon

    journey.status = JourneyStatus.COMPLETED
    journey.end_time = datetime.now(timezone.utc)
    db.commit()
    db.refresh(journey)

    # Invalidate active journey in Redis
    cache_service.delete_active_journey(journey.id)

    # Revoke active shares
    shares = db.query(JourneyShare).filter(JourneyShare.journey_id == journey.id, JourneyShare.is_revoked == False).all()
    for s in shares:
        s.is_revoked = True
    db.commit()

    log_action(db, action="JOURNEY_COMPLETED", resource_type="JOURNEY", resource_id=journey.id, user_id=user.id)
    return journey


def create_journey_share(db: Session, user: User, journey_id: str, data: JourneyShareCreate) -> JourneyShare:
    journey = db.query(Journey).filter(Journey.id == journey_id, Journey.user_id == user.id).first()
    if not journey:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Journey not found.")

    token = generate_secure_token(24)
    expires_at = datetime.now(timezone.utc) + timedelta(minutes=data.duration_minutes)

    share = JourneyShare(
        journey_id=journey.id,
        share_token=token,
        expires_at=expires_at,
        is_revoked=False,
        views_count=0
    )
    db.add(share)
    db.commit()
    db.refresh(share)

    log_action(db, action="JOURNEY_SHARE_CREATED", resource_type="JOURNEY_SHARE", resource_id=share.id, user_id=user.id)
    return share


def get_public_share_data(db: Session, share_token: str) -> dict:
    share = db.query(JourneyShare).filter(JourneyShare.share_token == share_token).first()
    if not share:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Share token not found or invalid.")

    now = datetime.now(timezone.utc)
    expires_at = share.expires_at
    if expires_at.tzinfo is None:
        expires_at = expires_at.replace(tzinfo=timezone.utc)

    if share.is_revoked or expires_at < now:
        raise HTTPException(
            status_code=status.HTTP_410_GONE,
            detail="This journey sharing session has expired or been revoked by the owner."
        )

    # Increment view count
    share.views_count += 1
    db.commit()

    journey = share.journey
    return {
        "journey_id": journey.id,
        "status": journey.status,
        "destination_name": journey.destination_name,
        "current_lat": journey.current_lat,
        "current_lon": journey.current_lon,
        "start_time": journey.start_time,
        "last_update_time": journey.locations[-1].timestamp if journey.locations else journey.start_time,
        "total_distance_km": journey.total_distance_km,
        "expires_at": share.expires_at,
        "is_valid": True
    }


def revoke_journey_share(db: Session, user: User, share_id: str) -> bool:
    share = db.query(JourneyShare).join(Journey).filter(
        JourneyShare.id == share_id,
        Journey.user_id == user.id
    ).first()
    if not share:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Share record not found.")

    share.is_revoked = True
    db.commit()
    log_action(db, action="JOURNEY_SHARE_REVOKED", resource_type="JOURNEY_SHARE", resource_id=share.id, user_id=user.id)
    return True
