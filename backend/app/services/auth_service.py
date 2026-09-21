from typing import Optional
from sqlalchemy.orm import Session
from fastapi import HTTPException, status
from backend.app.models.user import User, UserRole
from backend.app.schemas.user import UserRegister, UserLogin, PasswordChange, PrivacySettingsUpdate, UserUpdate
from backend.app.core.security import get_password_hash, verify_password, create_access_token
from backend.app.services.audit_service import log_action


def register_user(db: Session, data: UserRegister, role: UserRole = UserRole.USER) -> User:
    existing = db.query(User).filter(User.email == data.email).first()
    if existing:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="An account with this email address already exists."
        )

    if data.phone:
        existing_phone = db.query(User).filter(User.phone == data.phone).first()
        if existing_phone:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="An account with this phone number already exists."
            )

    user = User(
        email=data.email,
        hashed_password=get_password_hash(data.password),
        full_name=data.full_name,
        phone=data.phone,
        role=role,
        is_active=True
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    log_action(db, action="USER_REGISTERED", resource_type="USER", resource_id=user.id, user_id=user.id)
    return user


def authenticate_user(db: Session, data: UserLogin) -> dict:
    user = db.query(User).filter(User.email == data.email).first()
    if not user or not verify_password(data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password."
        )

    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="This account has been deactivated."
        )

    token = create_access_token({"sub": user.id, "email": user.email, "role": user.role.value})
    log_action(db, action="USER_LOGIN", resource_type="USER", resource_id=user.id, user_id=user.id)
    return {
        "access_token": token,
        "token_type": "bearer",
        "user_id": user.id,
        "email": user.email,
        "full_name": user.full_name,
        "role": user.role
    }


def change_user_password(db: Session, user: User, data: PasswordChange) -> bool:
    if not verify_password(data.old_password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Current password is incorrect."
        )

    user.hashed_password = get_password_hash(data.new_password)
    db.commit()
    log_action(db, action="PASSWORD_CHANGED", resource_type="USER", resource_id=user.id, user_id=user.id)
    return True


def update_privacy_settings(db: Session, user: User, data: PrivacySettingsUpdate) -> User:
    if data.safety_network_opt_in is not None:
        user.safety_network_opt_in = data.safety_network_opt_in
    if data.location_retention_days is not None:
        user.location_retention_days = data.location_retention_days
    db.commit()
    db.refresh(user)
    log_action(db, action="PRIVACY_SETTINGS_UPDATED", resource_type="USER", resource_id=user.id, user_id=user.id)
    return user


def update_profile(db: Session, user: User, data: UserUpdate) -> User:
    if data.full_name is not None:
        user.full_name = data.full_name
    if data.phone is not None:
        user.phone = data.phone
    db.commit()
    db.refresh(user)
    return user
