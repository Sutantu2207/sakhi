# SAKHI — System Architecture & Data Flow

## 1. High-Level Architecture

SAKHI provides a privacy-first women's safety and emergency support platform. The system operates across four primary tiers:

```
                      +-----------------------------+
                      |     Flutter Mobile App      |
                      | (Android / iOS / Web / Win) |
                      +--------------+--------------+
                                     |
                                 HTTPS / REST
                                     |
                      +--------------v--------------+
                      |       FastAPI Backend       |
                      |     (Python 3.11+, JWT)     |
                      +-------+--------------+------+
                              |              |
                +-------------v----+   +-----v-------------+
                | PostgreSQL +     |   | Redis 7           |
                | PostGIS Database |   | - Active journeys |
                | (Persistent Data)|   | - Network presence|
                +-------------+----+   | - Ephemeral SOS   |
                              |        +-------------------+
                +-------------v----+
                |  XGBoost ML Risk |
                |  Analysis Engine |
                +-------------+----+
                              |
                      +-------v---------------------+
                      | React Admin Dashboard       |
                      | (Vite, TypeScript, Tailwind)|
                      +-----------------------------+
```

---

## 2. Core Subsystems

### 2.1 Mobile Application (Flutter)
- **Framework**: Flutter Material3 with Provider state management.
- **Location Engine**: High-precision Geolocator GPS integration with automatic fallback for desktop/web testing.
- **Safety Features**:
  - 5-second countdown Emergency SOS with abort capability.
  - Temporary live journey sharing with unguessable tokens and TTLs.
  - Interactive incident and emergency facility map.
  - Direct legal rights and helpline navigator (112, 1091, 1930).
  - Confidential anonymous incident reporting.
  - Privacy dashboard with data retention and safety network toggles.

### 2.2 Backend Service (FastAPI)
- **Framework**: FastAPI with Pydantic v2 schemas and SQLAlchemy ORM.
- **Authentication**: JWT tokens (HS256) with bcrypt password hashing.
- **Dual-Mode Persistence Layer**:
  - *Production*: PostgreSQL with PostGIS spatial extension.
  - *Local Dev*: SQLite with embedded spherical Haversine spatial math.
- **Dual-Mode Caching Layer**:
  - *Production*: Redis 7 with geospatial index queries.
  - *Local Dev*: Thread-safe in-memory cache store with exact same API.

### 2.3 Contextual Risk Assessment Engine (ML)
- **Algorithm**: XGBoost Multi-Class Classifier (`sakhi-risk-xgb-v1.0`).
- **Input Features**: Incident densities (500m, 1km), weighted severity score, street harassment frequency, lighting quality, proximity to nearest police and hospital, hour-of-day, night indicator.
- **Ethical Rule**: Evaluates environmental and reported incident factors only. Never profiles individuals or predicts individual criminal acts.

### 2.4 Administrative Portal (React + Vite)
- **Stack**: React 18, Vite 5, TypeScript, Tailwind CSS, Leaflet.
- **Modules**:
  - Operations Overview with live counters.
  - Geospatial Incident & Risk Zone Map.
  - Incident Moderation Queue (Verify, Reject, Resolve).
  - Emergency SOS Command Center (Real-time alert dispatches).
  - Resource Management (Police, Hospitals, Shelters).
  - Risk Analytics (Feature weights, category distributions).
  - Compliance Audit Trail.
