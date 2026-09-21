from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
from backend.app.core.config import settings
from backend.app.db.session import engine
from backend.app.db.base import Base
from backend.app.api.v1.api_router import api_router
from backend.seeds.seed_data import seed_database


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup: ensure tables exist and seed initial resources
    Base.metadata.create_all(bind=engine)
    try:
        seed_database()
    except Exception as e:
        print(f"Seed note: {e}")
    yield
    # Shutdown logic if any


app = FastAPI(
    title=settings.PROJECT_NAME,
    version=settings.VERSION,
    description="Privacy-First Women's Safety & Emergency Support Network Backend API",
    lifespan=lifespan,
    docs_url="/docs",
    redoc_url="/redoc"
)

# CORS Middleware configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include v1 router
app.include_router(api_router, prefix=settings.API_V1_STR)


@app.get("/")
def root():
    return {
        "project": settings.PROJECT_NAME,
        "version": settings.VERSION,
        "status": "ONLINE",
        "docs": "/docs",
        "safety_principle": "Sakhi helps you make informed safety decisions and access support faster."
    }


@app.get("/health")
def healthcheck():
    return {
        "status": "HEALTHY",
        "service": "sakhi-api-gateway"
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("backend.app.main:app", host="127.0.0.1", port=8000, reload=True)
