import uuid
from datetime import datetime, timezone
from typing import Dict, Any, List
from sqlalchemy.orm import Session
from backend.app.models.user import User
from backend.app.models.sos import SOSEvent, SOSStatus
from backend.app.schemas.network import MeshPacketIngest, MeshPacketResponse, MeshStatusResponse, EmergencyHelpline
from backend.app.services.cache_service import cache_service
from backend.app.services.audit_service import log_action
from backend.app.utils.geo import get_approx_cell

# In-memory mesh statistics and deduplication fallback store
_mesh_stats = {
    "total_packets": 0,
    "sos_packets": 0,
    "last_packet_time": None,
    "gateways": set(),
}
_seen_packets_cache = {}


def register_presence(user: User, latitude: float, longitude: float) -> Dict[str, Any]:
    if not user.safety_network_opt_in:
        return {
            "opted_in": False,
            "nearby_participants_count": 0,
            "approximate_cell": "Disabled",
            "message": "Safety Network is currently disabled in your privacy settings."
        }

    # Store presence with 10-minute TTL (600s)
    cache_service.set_presence(user.id, latitude, longitude, ttl=600)

    # Get approximate nearby count within 3km
    count = cache_service.get_nearby_presence_count(latitude, longitude, radius_km=3.0)
    approx_cell = get_approx_cell(latitude, longitude, precision=2)

    return {
        "opted_in": True,
        "nearby_participants_count": max(1, count),  # includes self
        "approximate_cell": approx_cell,
        "message": f"Connected to Sakhi community network cell ({approx_cell}). Zero personal data shared."
    }


def leave_network(user: User):
    cache_service.remove_presence(user.id)


def ingest_mesh_packet(db: Session, packet: MeshPacketIngest) -> MeshPacketResponse:
    """
    Ingests an emergency packet forwarded by an ESP32 Gateway via ESP-NOW/BLE.
    Performs deduplication, updates mesh telemetry, and creates an anonymous emergency event.
    """
    now = datetime.now(timezone.utc)
    now_iso = now.isoformat()
    now_ts = now.timestamp()

    # 1. Deduplication check (10 min window)
    dedup_key = f"mesh:seen:{packet.message_id}"
    if dedup_key in _seen_packets_cache and (now_ts - _seen_packets_cache[dedup_key]) < 600:
        return MeshPacketResponse(
            status="DUPLICATE",
            message_id=packet.message_id,
            sos_id=None,
            ack_timestamp=now_iso,
            relayed_by_gateway=packet.gateway_id or "ESP32-GW-01",
            deduplicated=True
        )

    _seen_packets_cache[dedup_key] = now_ts

    # 2. Update mesh stats
    _mesh_stats["total_packets"] += 1
    _mesh_stats["last_packet_time"] = now_iso
    if packet.gateway_id:
        _mesh_stats["gateways"].add(packet.gateway_id)

    sos_id = None
    if packet.message_type.upper() == "SOS":
        _mesh_stats["sos_packets"] += 1

        # Check if an existing active anonymous mesh SOS exists with this ephemeral ID
        existing_mesh_sos = db.query(SOSEvent).filter(
            SOSEvent.address_approx.like(f"%Mesh Beacon: {packet.ephemeral_id[:8]}%"),
            SOSEvent.status.in_([SOSStatus.ACTIVE, SOSStatus.ACKNOWLEDGED])
        ).first()

        if existing_mesh_sos:
            existing_mesh_sos.latitude = packet.latitude
            existing_mesh_sos.longitude = packet.longitude
            existing_mesh_sos.accuracy_meters = packet.accuracy_meters or 15.0
            db.commit()
            db.refresh(existing_mesh_sos)
            sos_id = existing_mesh_sos.id
        else:
            # Look up or assign to system fallback mesh reporter account
            system_user = db.query(User).filter(User.email == "mesh-gateway@sakhi.network").first()
            if not system_user:
                system_user = db.query(User).first()
            if not system_user:
                from backend.app.core.security import get_password_hash
                system_user = User(
                    email="mesh-gateway@sakhi.network",
                    full_name="Emergency Mesh System Relay",
                    phone="+910000000000",
                    hashed_password=get_password_hash("MeshGateway2026!"),
                    is_active=True
                )
                db.add(system_user)
                db.commit()
                db.refresh(system_user)

            new_sos = SOSEvent(
                user_id=system_user.id,
                status=SOSStatus.ACTIVE,
                latitude=packet.latitude,
                longitude=packet.longitude,
                accuracy_meters=packet.accuracy_meters or 15.0,
                address_approx=f"Emergency Mesh Relay (Hops: {packet.hop_count}, GW: {packet.gateway_id}, Mesh Beacon: {packet.ephemeral_id[:8]}...)",
                triggered_at=now,
                contacts_notified_count=0,
                notification_status="MESH_RELAY_BROADCAST",
                admin_notes=f"Ingested from hardware mesh gateway {packet.gateway_id}. TTL remaining: {packet.ttl}."
            )
            db.add(new_sos)
            db.commit()
            db.refresh(new_sos)
            sos_id = new_sos.id

        log_action(
            db,
            action="MESH_EMERGENCY_PACKET_INGESTED",
            resource_type="MESH",
            resource_id=packet.message_id,
            user_id=system_user.id if 'system_user' in locals() and system_user else existing_mesh_sos.user_id,
            details=f"Gateway: {packet.gateway_id}, Ephemeral: {packet.ephemeral_id[:8]}, Hops: {packet.hop_count}, Lat: {packet.latitude}, Lon: {packet.longitude}"
        )

    return MeshPacketResponse(
        status="PROCESSED",
        message_id=packet.message_id,
        sos_id=sos_id,
        ack_timestamp=now_iso,
        relayed_by_gateway=packet.gateway_id or "ESP32-GW-01",
        deduplicated=False
    )


def get_mesh_status() -> MeshStatusResponse:
    return MeshStatusResponse(
        status="OPERATIONAL",
        active_gateways_count=max(1, len(_mesh_stats["gateways"])),
        total_packets_relayed=_mesh_stats["total_packets"],
        emergency_sos_packets_count=_mesh_stats["sos_packets"],
        last_packet_received_at=_mesh_stats["last_packet_time"],
        simulation_mode=True
    )


def get_emergency_helplines() -> List[EmergencyHelpline]:
    return [
        EmergencyHelpline(
            number="112",
            name="National Emergency Support",
            category="Police, Fire, Medical",
            badge_color="#E63946",
            description="Pan-India single emergency number with real-time CAD dispatch integration.",
            priority=1
        ),
        EmergencyHelpline(
            number="181",
            name="Women Helpline (Domestic & Crisis)",
            category="Harassment & Crisis Referral",
            badge_color="#7B2CBF",
            description="24/7 dedicated support for women facing violence, harassment, or in need of shelter.",
            priority=2
        ),
        EmergencyHelpline(
            number="1930",
            name="Cyber Crime & Financial Fraud",
            category="Online Harassment & Fraud",
            badge_color="#0077B6",
            description="National cybercrime reporting for cyberstalking, non-consensual images, and fraud.",
            priority=3
        ),
        EmergencyHelpline(
            number="1098",
            name="Childline Emergency Service",
            category="Children & Minor Protection",
            badge_color="#FB8500",
            description="24/7 free emergency helpline for children and minors in distress or danger.",
            priority=4
        )
    ]
