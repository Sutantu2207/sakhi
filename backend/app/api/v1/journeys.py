from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from backend.app.db.session import get_db
from backend.app.api.deps import get_current_user
from backend.app.models.user import User
from backend.app.models.journey import Journey, JourneyStatus, JourneyShare
from backend.app.schemas.journey import (
    JourneyStart, JourneyLocationPing, JourneyEnd, JourneyOut,
    JourneyShareCreate, JourneyShareOut
)
from backend.app.services.journey_service import (
    start_journey, record_location_ping, end_journey,
    create_journey_share, revoke_journey_share
)

router = APIRouter(prefix="/journeys", tags=["Journeys & Tracking"])


@router.post("/start", response_model=JourneyOut, status_code=status.HTTP_201_CREATED)
def api_start_journey(
    data: JourneyStart,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    return start_journey(db, current_user, data)


@router.post("/{journey_id}/location", response_model=JourneyOut)
def api_record_location(
    journey_id: str,
    data: JourneyLocationPing,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    return record_location_ping(db, current_user, journey_id, data)


@router.post("/{journey_id}/end", response_model=JourneyOut)
def api_end_journey(
    journey_id: str,
    data: Optional[JourneyEnd] = None,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    return end_journey(db, current_user, journey_id, data)


@router.get("/active", response_model=Optional[JourneyOut])
def api_get_active_journey(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    journey = db.query(Journey).filter(
        Journey.user_id == current_user.id,
        Journey.status.in_([JourneyStatus.STARTED, JourneyStatus.ACTIVE])
    ).first()
    return journey


@router.get("/history", response_model=List[JourneyOut])
def api_get_journey_history(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    return db.query(Journey).filter(
        Journey.user_id == current_user.id,
        Journey.status.in_([JourneyStatus.COMPLETED, JourneyStatus.CANCELLED])
    ).order_by(Journey.created_at.desc()).limit(20).all()


@router.post("/{journey_id}/share", response_model=JourneyShareOut)
def api_share_journey(
    journey_id: str,
    data: JourneyShareCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    share = create_journey_share(db, current_user, journey_id, data)
    return {
        "id": share.id,
        "journey_id": share.journey_id,
        "share_token": share.share_token,
        "expires_at": share.expires_at,
        "is_revoked": share.is_revoked,
        "views_count": share.views_count,
        "created_at": share.created_at,
        "share_url": f"/public/share/{share.share_token}"
    }


@router.delete("/shares/{share_id}", status_code=status.HTTP_204_NO_CONTENT)
def api_revoke_share(
    share_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    revoke_journey_share(db, current_user, share_id)
    return None
