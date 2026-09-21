import uuid
from datetime import datetime, timezone
import enum
from sqlalchemy import Column, String, Float, DateTime, ForeignKey, Enum as SQLEnum, Integer, Boolean
from sqlalchemy.orm import relationship
from backend.app.db.session import Base


class JourneyStatus(str, enum.Enum):
    STARTED = "STARTED"
    ACTIVE = "ACTIVE"
    PAUSED = "PAUSED"
    COMPLETED = "COMPLETED"
    CANCELLED = "CANCELLED"


class Journey(Base):
    __tablename__ = "journeys"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    status = Column(SQLEnum(JourneyStatus), default=JourneyStatus.STARTED, nullable=False, index=True)
    destination_name = Column(String(255), nullable=True)
    start_lat = Column(Float, nullable=False)
    start_lon = Column(Float, nullable=False)
    current_lat = Column(Float, nullable=True)
    current_lon = Column(Float, nullable=True)
    destination_lat = Column(Float, nullable=True)
    destination_lon = Column(Float, nullable=True)
    start_time = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)
    end_time = Column(DateTime, nullable=True)
    total_distance_km = Column(Float, default=0.0, nullable=False)
    max_reported_risk_encountered = Column(String(50), default="lower_reported_risk", nullable=False)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)

    user = relationship("User", back_populates="journeys")
    locations = relationship("JourneyLocation", back_populates="journey", cascade="all, delete-orphan", order_by="JourneyLocation.timestamp")
    shares = relationship("JourneyShare", back_populates="journey", cascade="all, delete-orphan")


class JourneyLocation(Base):
    __tablename__ = "journey_locations"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    journey_id = Column(String(36), ForeignKey("journeys.id", ondelete="CASCADE"), nullable=False, index=True)
    latitude = Column(Float, nullable=False)
    longitude = Column(Float, nullable=False)
    speed = Column(Float, nullable=True)
    accuracy = Column(Float, nullable=True)
    timestamp = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False, index=True)

    journey = relationship("Journey", back_populates="locations")


class JourneyShare(Base):
    __tablename__ = "journey_shares"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    journey_id = Column(String(36), ForeignKey("journeys.id", ondelete="CASCADE"), nullable=False, index=True)
    share_token = Column(String(128), unique=True, index=True, nullable=False)
    expires_at = Column(DateTime, nullable=False, index=True)
    is_revoked = Column(Boolean, default=False, nullable=False)
    views_count = Column(Integer, default=0, nullable=False)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)

    journey = relationship("Journey", back_populates="shares")
