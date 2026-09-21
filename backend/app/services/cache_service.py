import json
import time
import threading
import logging
from typing import Optional, Dict, Any
import redis
from backend.app.core.config import settings
from backend.app.utils.geo import is_within_radius

logger = logging.getLogger(__name__)


class InMemoryCacheStore:
    def __init__(self):
        self._store: Dict[str, Any] = {}
        self._expires: Dict[str, float] = {}
        self._lock = threading.Lock()
        # Storage for safety network presence: {user_id: {"lat": float, "lon": float, "expires": float}}
        self._presence: Dict[str, Dict[str, Any]] = {}

    def _cleanup(self):
        now = time.time()
        expired_keys = [k for k, exp in self._expires.items() if exp <= now]
        for k in expired_keys:
            self._store.pop(k, None)
            self._expires.pop(k, None)

        expired_presence = [uid for uid, p in self._presence.items() if p["expires"] <= now]
        for uid in expired_presence:
            self._presence.pop(uid, None)

    def set(self, key: str, value: str, ex: Optional[int] = None) -> bool:
        with self._lock:
            self._cleanup()
            self._store[key] = value
            if ex:
                self._expires[key] = time.time() + ex
            else:
                self._expires.pop(key, None)
            return True

    def get(self, key: str) -> Optional[str]:
        with self._lock:
            self._cleanup()
            if key in self._expires and self._expires[key] <= time.time():
                self._store.pop(key, None)
                self._expires.pop(key, None)
                return None
            return self._store.get(key)

    def delete(self, key: str) -> bool:
        with self._lock:
            self._expires.pop(key, None)
            return self._store.pop(key, None) is not None

    def add_presence(self, user_id: str, lat: float, lon: float, ttl: int = 600) -> bool:
        with self._lock:
            self._cleanup()
            self._presence[user_id] = {
                "lat": lat,
                "lon": lon,
                "expires": time.time() + ttl
            }
            return True

    def remove_presence(self, user_id: str) -> bool:
        with self._lock:
            return self._presence.pop(user_id, None) is not None

    def get_nearby_presence_count(self, lat: float, lon: float, radius_km: float = 3.0) -> int:
        with self._lock:
            self._cleanup()
            count = 0
            for p in self._presence.values():
                if is_within_radius(lat, lon, p["lat"], p["lon"], radius_km):
                    count += 1
            return count


class CacheService:
    def __init__(self):
        self._redis_client = None
        self._in_memory = InMemoryCacheStore()
        self._use_redis = False
        self._init_redis()

    def _init_redis(self):
        try:
            client = redis.Redis.from_url(settings.REDIS_URL, decode_responses=True, socket_timeout=1)
            client.ping()
            self._redis_client = client
            self._use_redis = True
            logger.info("Successfully connected to Redis at %s", settings.REDIS_URL)
        except Exception as e:
            self._use_redis = False
            logger.info("Redis not reachable (%s). Using thread-safe in-memory cache fallback.", str(e))

    def set(self, key: str, value: Any, ex: Optional[int] = None) -> bool:
        val_str = json.dumps(value) if not isinstance(value, str) else value
        if self._use_redis:
            try:
                return bool(self._redis_client.set(key, val_str, ex=ex))
            except Exception:
                pass
        return self._in_memory.set(key, val_str, ex=ex)

    def get(self, key: str) -> Optional[Any]:
        if self._use_redis:
            try:
                res = self._redis_client.get(key)
                if res is not None:
                    try:
                        return json.loads(res)
                    except Exception:
                        return res
            except Exception:
                pass
        res = self._in_memory.get(key)
        if res is not None:
            try:
                return json.loads(res)
            except Exception:
                return res
        return None

    def delete(self, key: str) -> bool:
        if self._use_redis:
            try:
                return bool(self._redis_client.delete(key))
            except Exception:
                pass
        return self._in_memory.delete(key)

    # Active Journey State in Cache
    def set_active_journey(self, journey_id: str, data: dict, ttl: int = 86400):
        key = f"active_journey:{journey_id}"
        self.set(key, data, ex=ttl)

    def get_active_journey(self, journey_id: str) -> Optional[dict]:
        key = f"active_journey:{journey_id}"
        return self.get(key)

    def delete_active_journey(self, journey_id: str):
        key = f"active_journey:{journey_id}"
        self.delete(key)

    # Safety Network Presence
    def set_presence(self, user_id: str, lat: float, lon: float, ttl: int = 600):
        if self._use_redis:
            try:
                # Store in Redis geospatial index
                self._redis_client.geoadd("safety_network_presence", (lon, lat, user_id))
                self._redis_client.expire("safety_network_presence", ttl)
                return True
            except Exception:
                pass
        return self._in_memory.add_presence(user_id, lat, lon, ttl)

    def remove_presence(self, user_id: str):
        if self._use_redis:
            try:
                self._redis_client.zrem("safety_network_presence", user_id)
                return True
            except Exception:
                pass
        return self._in_memory.remove_presence(user_id)

    def get_nearby_presence_count(self, lat: float, lon: float, radius_km: float = 3.0) -> int:
        if self._use_redis:
            try:
                # geosearch returns members within radius
                members = self._redis_client.geosearch(
                    "safety_network_presence",
                    latitude=lat,
                    longitude=lon,
                    radius=radius_km,
                    unit="km"
                )
                return len(members)
            except Exception:
                pass
        return self._in_memory.get_nearby_presence_count(lat, lon, radius_km)

    # Temporary SOS Active state
    def set_active_sos(self, sos_id: str, data: dict, ttl: int = 86400):
        key = f"active_sos:{sos_id}"
        self.set(key, data, ex=ttl)

    def get_active_sos(self, sos_id: str) -> Optional[dict]:
        key = f"active_sos:{sos_id}"
        return self.get(key)

    def delete_active_sos(self, sos_id: str):
        key = f"active_sos:{sos_id}"
        self.delete(key)


cache_service = CacheService()
