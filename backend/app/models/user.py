import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, Boolean, DateTime, Enum as SQLEnum, Integer
from sqlalchemy.orm import relationship
import enum
from backend.app.db.session import Base


class UserRole(str, enum.Enum):
    USER = "USER"
    MODERATOR = "MODERATOR"
    ADMIN = "ADMIN"


class User(Base):
    __tablename__ = "users"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    email = Column(String(255), unique=True, index=True, nullable=False)
    phone = Column(String(30), unique=True, index=True, nullable=True)
    full_name = Column(String(255), nullable=False)
    hashed_password = Column(String(255), nullable=False)
    role = Column(SQLEnum(UserRole), default=UserRole.USER, nullable=False)
    is_active = Column(Boolean, default=True, nullable=False)
    safety_network_opt_in = Column(Boolean, default=False, nullable=False)
    location_retention_days = Column(Integer, default=7, nullable=False)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)
    updated_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc), nullable=False)

    emergency_contacts = relationship("EmergencyContact", back_populates="user", cascade="all, delete-orphan")
    journeys = relationship("Journey", back_populates="user", cascade="all, delete-orphan")
    sos_events = relationship("SOSEvent", back_populates="user", cascade="all, delete-orphan")
    incidents = relationship("Incident", back_populates="reporter")
