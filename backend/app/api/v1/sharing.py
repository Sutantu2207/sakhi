from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from backend.app.db.session import get_db
from backend.app.schemas.journey import PublicShareAccessOut
from backend.app.services.journey_service import get_public_share_data

router = APIRouter(prefix="/public", tags=["Public Temporary Journey Sharing"])


@router.get("/share/{share_token}", response_model=PublicShareAccessOut)
def api_view_shared_journey(
    share_token: str,
    db: Session = Depends(get_db)
):
    """
    Authorized read-only public endpoint to view temporary live journey.
    Protected by high-entropy unguessable token and strict expiry/revocation logic.
    """
    return get_public_share_data(db, share_token)
