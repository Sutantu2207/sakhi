# SAKHI — Privacy-First Women's Safety & Emergency Support Network

<p align="center">
  <b>Travel safer. Respond faster. Stay connected.</b>
</p>

---

## 1. Problem Statement & Philosophy

> **Sakhi – Develop a privacy-focused platform that guides women toward appropriate legal, emergency and support resources during harassment, abuse or cybercrime situations.**

### Core Product Principle:
**Sakhi does NOT claim or guarantee absolute safety.**
Rather, Sakhi's purpose is to **help women make informed safety decisions, reduce friction during emergencies, and access support faster**.

---

## 2. Master System Architecture

```text
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

## 3. Technology Stack

- **Mobile Client**: Flutter 3.47+ (Dart 3.13+), Material3, Provider state management, Geolocator GPS engine.
- **Backend API**: Python 3.11+, FastAPI, SQLAlchemy, Pydantic v2, JWT, bcrypt.
- **Database Layer**: PostgreSQL 15 + PostGIS (primary production target) with automatic resilient SQLite spatial fallback for zero-dependency local development.
- **Caching & Ephemeral Layer**: Redis 7 (primary) with thread-safe in-memory cache store fallback.
- **Machine Learning**: XGBoost Multi-Class Classifier (`sakhi-risk-xgb-v1.0`), Pandas, NumPy, Scikit-learn.
- **Admin Dashboard**: React 18, Vite 5, TypeScript, Tailwind CSS, Leaflet Maps.
- **Deployment**: Docker, Docker Compose, Nginx, cloud-ready configurations.

---

## 4. Key Capabilities & Modules

### 4.1 Real-Time Emergency SOS Engine
- Prominent accessible SOS button with an interactive 5-second countdown and abort dialog.
- Captures high-precision GPS coordinates, notifies emergency contacts, and creates an emergency dispatch event.
- Live SOS status view with green checklists (Location captured, Contacts notified, Sharing active).
- Emergency dialer shortcuts (112, 1091, 1930) and cancellation workflow.

### 4.2 Journey Mode & Temporary Sharing
- Live journey tracking with distance, elapsed time, and contextual route risk.
- Cryptographically secure 192-bit temporary sharing tokens with configurable expiration (15m, 30m, 60m).
- Public read-only view for trusted contacts; returns HTTP `410 Gone` upon completion or revocation.

### 4.3 Contextual Geospatial Risk Assessment (ML)
- Trained XGBoost multi-class classifier evaluating verified incident densities, lighting quality, temporal risk windows, and proximity to emergency posts.
- Outputs calm, non-alarmist descriptions: *"Moderate reported-risk context based on available incident data"*.
- Strict ethical AI guardrail: **Never profiles individuals or predicts individual criminal acts**.

### 4.4 Community Safety Network
- Opt-in neighborhood presence using coarse 1.1km spatial grid cells.
- Displays approximate nearby user counts (`12 participants nearby`) with **zero personal identity, name, phone, or exact coordinate exposure**.

### 4.5 Confidential Incident Reporting
- Report street harassment, poor lighting, stalking, assault, or cybercrime.
- Optional anonymous reporting scrubs the user ID from the report record.
- Subject to administrative review and ground verification.

### 4.6 Nearby Emergency Help & Legal Support Navigator
- Proximity discovery for verified police stations, hospitals, fire stations, and women's crisis centers.
- Direct legal rights navigation for IPC/BNS provisions, PoSH (Workplace Harassment), Domestic Violence Act, and Cybercrime reporting.

### 4.7 Operations & Admin Console (React + Leaflet)
- Real-time operational overview counters.
- Geospatial incident map with severity heat clusters and multi-filter toolbar.
- Moderation queue with verification actions and audit logging.
- Emergency SOS Command Center with live dispatch timers, victim details, and resolution notes.

---

## 5. Development & Startup Instructions

### 5.1 Option A: Docker Compose (Postgres + Redis + FastAPI)
```bash
# Copy environment configuration
cp .env.example .env

# Launch services
docker compose up -d

# Verify API health
curl http://localhost:8000/health
```

### 5.2 Option B: Native Zero-Dependency Local Startup (Windows / macOS / Linux)

#### 1. Backend Service:
```powershell
# Activate virtual environment
.\.venv\Scripts\activate

# Run database seeder (initializes sample resources, admin account, and incidents)
python backend/seeds/seed_data.py

# Start FastAPI server
uvicorn backend.app.main:app --host 127.0.0.1 --port 8000 --reload
```
*API documentation available at: `http://127.0.0.1:8000/docs`*

#### 2. React Admin Dashboard:
```powershell
cd admin
npm run dev
```
*Dashboard opens at: `http://localhost:5173`*

#### 3. Mobile Application:
```powershell
cd mobile
flutter run -d chrome    # Or flutter run for Android/Windows
```

---

## 6. Seed Accounts for Testing & Review

| Role | Email | Password | Access / Capabilities |
|---|---|---|---|
| **Central Admin** | `admin@sakhi.network` | `Admin@Sakhi2026` | Admin Console, SOS Command Center, Incident Moderation, Resource Management |
| **Test User** | `priya@example.com` | `SakhiUser123!` | Mobile App, Journey Tracking, SOS trigger, 2 Pre-configured Emergency Contacts |

---

## 7. Verification & Automated Tests

### Run Backend Pytest Suite:
```powershell
.\.venv\Scripts\pytest.exe backend\tests -v
```
*13 / 13 test suites passing (Auth, Journeys, SOS, Incidents, Spatial proximity, Route risk).*

### Run ML Pipeline & Evaluation:
```powershell
.\.venv\Scripts\python.exe ml\training\train_model.py
```
*Evaluates XGBoost classifier, outputs confusion matrix and feature weights (86.8% accuracy).*

### Run Flutter Widget & Unit Tests:
```powershell
cd mobile
flutter test
```
*All Flutter widget tests passing.*

---

## 8. Documentation Index

- [Architecture & Data Flow](docs/architecture.md)
- [REST API Specifications](docs/api.md)
- [Privacy & Threat Model](docs/privacy.md)
- [Security & RBAC Controls](docs/security.md)
- [Machine Learning Risk Engine](docs/ml.md)
- [BLE Emergency Relay Specification](docs/ble_relay_specification.md)
- [Deployment & Operations](docs/deployment.md)
- [Testing & Quality Assurance](docs/testing.md)

---

<p align="center">
  <b>Built with care for women's safety, privacy, and emergency responsiveness.</b>
</p>
