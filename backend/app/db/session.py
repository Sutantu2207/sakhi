import math
from sqlalchemy import create_engine, event
from sqlalchemy.orm import declarative_base, sessionmaker
from backend.app.core.config import settings

Base = declarative_base()

# SQLite specific connect args
connect_args = {}
if settings.DATABASE_URL.startswith("sqlite"):
    connect_args = {"check_same_thread": False}

engine = create_engine(
    settings.DATABASE_URL,
    connect_args=connect_args,
    pool_pre_ping=True
)

# If SQLite is used in local development mode, attach custom math functions
if settings.DATABASE_URL.startswith("sqlite"):
    @event.listens_for(engine, "connect")
    def connect(dbapi_con, con_record):
        dbapi_con.create_function("cos", 1, math.cos)
        dbapi_con.create_function("sin", 1, math.sin)
        dbapi_con.create_function("radians", 1, math.radians)
        dbapi_con.create_function("acos", 1, math.acos)
        dbapi_con.create_function("asin", 1, math.asin)
        dbapi_con.create_function("sqrt", 1, math.sqrt)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
