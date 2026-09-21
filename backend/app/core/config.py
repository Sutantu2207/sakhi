import os
from typing import List, Union
from pydantic_settings import BaseSettings
from pydantic import AnyHttpUrl, field_validator


class Settings(BaseSettings):
    PROJECT_NAME: str = "SAKHI — Women's Safety & Emergency Support Network"
    VERSION: str = "1.0.0"
    API_V1_STR: str = "/api/v1"
    
    # Security
    SECRET_KEY: str = os.getenv("JWT_SECRET", "sakhi-super-secure-privacy-first-key-2026-production")
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 7  # 7 days
    
    # Database
    # Primary is PostgreSQL + PostGIS; if not available, fallback to SQLite for local development
    DATABASE_URL: str = os.getenv("DATABASE_URL", "sqlite:///./sakhi_dev.db")
    
    # Redis
    REDIS_URL: str = os.getenv("REDIS_URL", "redis://localhost:6379/0")
    
    # CORS
    CORS_ORIGINS: List[str] = [
        "http://localhost:3000",
        "http://localhost:5173",
        "http://127.0.0.1:3000",
        "http://127.0.0.1:5173",
        "*"
    ]
    
    # Machine Learning Model Path
    ML_MODEL_PATH: str = os.getenv(
        "ML_MODEL_PATH",
        os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))), "..", "ml", "models", "sakhi_risk_model.joblib")
    )

    class Config:
        case_sensitive = True
        env_file = ".env"


settings = Settings()
