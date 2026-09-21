# SAKHI — Current Implementation Status & Audit Report

**Generated on:** September 21, 2026  
**Repository:** [https://github.com/Sutantu2207/sakhi](https://github.com/Sutantu2207/sakhi)  
**Specification:** Master Implementation Plan `Pasted markdown(3).md`

---

## Executive Summary

SAKHI is a multi-tier, privacy-first women's safety platform consisting of:
1. **FastAPI Backend** (`backend/`): JWT auth, dual PostGIS / SQLite spherical Haversine spatial engine, dual Redis / in-memory cache, 35+ REST endpoints, 13/13 passing Pytest test suite.
2. **Machine Learning Contextual Risk Engine** (`ml/`): XGBoost multi-class classifier evaluating environmental factors without individual profiling (86.8% macro validation accuracy).
3. **Admin Operations & Citizen Web Platform** (`admin/`): React 18, Vite, TypeScript, Tailwind CSS, Leaflet Maps with unified mode switcher between Admin Operations Console and Citizen Safety Dashboard.
4. **Flutter Mobile Application** (`mobile/`): Material 3, Provider state management, Geolocator GPS tracking, 5-second countdown emergency SOS, legal navigator, and passing widget tests.

---

## 1. Audit Categories

### 1.1 Backend Service (`backend/`)
| Component | Status | Details |
| :--- | :--- | :--- |
| **Authentication & RBAC** | **COMPLETE** | JWT bearer authentication, bcrypt hashing, role enforcement (`USER`, `MODERATOR`, `ADMIN`), `/auth/me`, privacy settings update. |
| **Database & Fallback** | **COMPLETE** | SQLAlchemy models with PostgreSQL/PostGIS in production; zero-dependency SQLite with spherical Haversine fallback for local environments. |
| **Emergency Contacts CRUD** | **COMPLETE** | Full CRUD on `/contacts`, validation, phone numbers, and SOS notification toggle. |
| **SOS System** | **PARTIAL** | State machine supports `CREATED`, `ACTIVE`, `ACKNOWLEDGED`, `RESOLVED`, `CANCELLED`, `EXPIRED`. Automatic duplicate suppression and contacts count tracking implemented. Needs tighter journey association linking and real-time WebSocket/SSE notification hooks. |
| **Journeys & Tracking** | **COMPLETE** | Start journey, ping location, calculate distance, and temporary sharing token with TTL & revocation. |
| **Geospatial & Risk APIs** | **COMPLETE** | Spatial discovery of resources within radius, incident proximity queries, and ML model inference integration. |
| **Audit Logging** | **COMPLETE** | Structured audit logging (`audit_service.py`) for security-critical operations (SOS, moderation, logins). |
| **Tests** | **COMPLETE** | 13/13 tests passing across auth, journeys, SOS, incidents, and spatial modules. |

### 1.2 Machine Learning Contextual Risk Engine (`ml/`)
| Component | Status | Details |
| :--- | :--- | :--- |
| **Dataset Generator** | **COMPLETE** | Synthetic and real environmental distribution generator (`ml/dataset/generate_dataset.py`) based on 500m & 1km incident counts, lighting, hour of day, and infrastructure proximity. |
| **Training Pipeline** | **COMPLETE** | XGBoost multi-class classifier (`ml/training/train_model.py`) with 86.8% macro accuracy, confusion matrix, and feature importances. |
| **Ethical AI Guardrails** | **COMPLETE** | Plain-English contributing factors; outputs non-alarmist categories (`lower_reported_risk`, `moderate_reported_risk`, `higher_reported_risk`); strictly avoids individual criminal prediction. |
| **Inference Service** | **COMPLETE** | `backend/app/ml/inference.py` evaluates single points and route waypoints dynamically. |

### 1.3 Web Applications (`admin/`)
| Component | Status | Details |
| :--- | :--- | :--- |
| **Admin Operations Overview** | **COMPLETE** | Real-time counters, active SOS feeds, moderation status, category distributions. |
| **SOS Command Center** | **COMPLETE** | Live queue of active/acknowledged SOS events, emergency contact count, coordinates, and resolution modals with audit notes. |
| **Incident Moderation Queue** | **COMPLETE** | Verification, rejection, and resolution actions with notes. |
| **Geospatial Incident Map** | **COMPLETE** | Leaflet maps rendering verified incidents, police posts, and hospitals. |
| **Citizen / User Safety Web Dashboard** | **COMPLETE** | Direct in-browser Citizen experience (`?mode=user`) with SOS Hero Button (5s countdown), Journey Guard, Leaflet map, confidential report form, 24/7 helpline calling, and privacy controls. |

### 1.4 Flutter Mobile Application (`mobile/`)
| Component | Status | Details |
| :--- | :--- | :--- |
| **Navigation & Screens** | **COMPLETE** | 13 screens covering Splash, Onboarding, Auth, Home, SOS Active, Journey, Map, Nearby Help, Report, Legal, Privacy, and Profile. |
| **SOS Flow UX** | **COMPLETE** | Accessible SOS button, 5-second abort countdown dialog, active state checklist, direct emergency dialers (112, 1091). |
| **State Management** | **COMPLETE** | Provider architecture with `AuthProvider`, `SosProvider`, `JourneyProvider`, and `SafetyProvider`. |
| **GPS & Location** | **COMPLETE** | Geolocator integration with accuracy tracking and permission checks. |
| **Web Server Mode** | **COMPLETE** | Serves cleanly via Flutter Web on `http://127.0.0.1:8080`. |
| **Experimental BLE Relay** | **PARTIAL** | Spec and rotating 128-bit ephemeral beacon structure implemented (`ble_relay_service.dart`); physical OS BLE mesh broadcasting requires platform channel hooks on physical hardware. |

---

## 2. Identified Weaknesses & Technical Debt

1. **Journey ↔ SOS Association**:
   - When SOS is triggered during an active journey, the backend should explicitly link the `journey_id` to the `SOSEvent` to give emergency responders the traveler's intended destination and route trail.
2. **Notification Realism**:
   - Currently, notifications to emergency contacts are recorded as `"SENT"` / `"NO_CONTACTS_CONFIGURED"` in the database. Adding SMS gateway abstraction (Twilio/AWS SNS stubs) makes the pipeline production-ready.
3. **Database Migration Pipeline (Alembic)**:
   - Tables are auto-created via `Base.metadata.create_all(bind=engine)`. Adding formal Alembic migration scripts ensures smooth PostgreSQL/PostGIS schema upgrades in staging and production.
4. **WebSocket / Real-time Push for Admin SOS**:
   - The Admin console polls every 15 seconds. Upgrading to a real-time event stream (SSE or WebSockets) gives sub-second dispatch alert times.

---

## 3. Priority Upgrade Roadmap

1. **Phase 1: SOS & Journey Association Hardening**
   - Add `journey_id` foreign key link on `SOSEvent`.
   - Update `trigger_sos()` to automatically bind any active journey for the user.
   - Return destination and route context in the Admin SOS Command Center.

2. **Phase 2: Notification Service Abstraction**
   - Create a clean `notification_service.py` with multi-channel dispatch (SMS, Push, In-App) supporting realistic delivery receipts.

3. **Phase 3: Real-Time SSE/WebSocket Stream**
   - Implement an SSE endpoint `/api/v1/sos/stream` for immediate alert broadcasting to the admin command center.

4. **Phase 4: Alembic Migrations & PostGIS Production Hardening**
   - Generate initial Alembic migration scripts.
