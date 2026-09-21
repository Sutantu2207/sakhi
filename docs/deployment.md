# SAKHI — Deployment & Operations Guide

## 1. Containerized Deployment (Docker Compose)

The repository provides a production-ready `docker-compose.yml` orchestrating:
- `db`: PostgreSQL 15 with PostGIS (`postgis/postgis:15-3.3`)
- `redis`: Redis 7 alpine (`redis:7-alpine`)
- `backend`: FastAPI app (`python:3.11-slim`)

### Quick Start:
```bash
# 1. Copy environment template
cp .env.example .env

# 2. Start all services
docker compose up -d

# 3. Verify health
docker compose ps
curl http://localhost:8000/health
```

---

## 2. Local Development Without Docker

For developer workstations where Docker is not installed, SAKHI provides zero-friction native execution:

### Backend:
```powershell
# In Sakhi root directory
.\.venv\Scripts\activate
uvicorn backend.app.main:app --host 127.0.0.1 --port 8000 --reload
```
*Backend automatically uses SQLite with embedded Haversine calculations and in-memory cache fallback.*

### Admin Dashboard:
```powershell
cd admin
npm run dev
# Dashboard opens on http://localhost:5173
```

### Mobile Application:
```powershell
cd mobile
flutter run -d chrome    # Or flutter run for Android/Windows
```

---

## 3. Cloud Deployment Targets

- **FastAPI Backend**: Render, Railway, or AWS Elastic Container Service (ECS).
- **Database**: Managed AWS RDS PostgreSQL with PostGIS, or Supabase PostgreSQL.
- **Cache**: Managed Upstash Redis or AWS ElastiCache.
- **Admin Portal**: Vercel, Netlify, or AWS CloudFront/S3.
