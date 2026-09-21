from fastapi import APIRouter
from backend.app.api.v1.auth import router as auth_router
from backend.app.api.v1.contacts import router as contacts_router
from backend.app.api.v1.journeys import router as journeys_router
from backend.app.api.v1.sos import router as sos_router
from backend.app.api.v1.incidents import router as incidents_router
from backend.app.api.v1.resources import router as resources_router
from backend.app.api.v1.risk import router as risk_router
from backend.app.api.v1.network import router as network_router
from backend.app.api.v1.admin import router as admin_router
from backend.app.api.v1.sharing import router as sharing_router

api_router = APIRouter()

api_router.include_router(auth_router)
api_router.include_router(contacts_router)
api_router.include_router(journeys_router)
api_router.include_router(sos_router)
api_router.include_router(incidents_router)
api_router.include_router(resources_router)
api_router.include_router(risk_router)
api_router.include_router(network_router)
api_router.include_router(admin_router)
api_router.include_router(sharing_router)
