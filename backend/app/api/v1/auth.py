from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from backend.app.db.session import get_db
from backend.app.schemas.user import (
    UserRegister, UserLogin, TokenResponse, UserOut,
    UserUpdate, PrivacySettingsUpdate, PasswordChange
)
from backend.app.services.auth_service import (
    register_user, authenticate_user, change_user_password,
    update_privacy_settings, update_profile
)
from backend.app.api.deps import get_current_user
from backend.app.models.user import User

router = APIRouter(prefix="/auth", tags=["Authentication & Profile"])


@router.post("/register", response_model=UserOut, status_code=status.HTTP_201_CREATED)
def register(data: UserRegister, db: Session = Depends(get_db)):
    return register_user(db, data)


@router.post("/login", response_model=TokenResponse)
def login(data: UserLogin, db: Session = Depends(get_db)):
    return authenticate_user(db, data)


@router.get("/me", response_model=UserOut)
def get_me(current_user: User = Depends(get_current_user)):
    return current_user


@router.put("/profile", response_model=UserOut)
def update_user_profile(
    data: UserUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    return update_profile(db, current_user, data)


@router.put("/privacy-settings", response_model=UserOut)
def update_user_privacy(
    data: PrivacySettingsUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    return update_privacy_settings(db, current_user, data)


@router.post("/change-password")
def change_password(
    data: PasswordChange,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    change_user_password(db, current_user, data)
    return {"message": "Password changed successfully."}
