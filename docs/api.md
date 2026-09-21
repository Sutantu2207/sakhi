# SAKHI — API Specifications & Endpoints

All endpoints are prefixed with `/api/v1`.
FastAPI Swagger documentation is accessible at: `http://127.0.0.1:8000/docs`.

---

## 1. Authentication & User Profile (`/auth`)

| Method | Endpoint | Description | Auth Required |
|---|---|---|---|
| `POST` | `/auth/register` | Register a new user account | No |
| `POST` | `/auth/login` | Authenticate with email/password; returns JWT token | No |
| `GET` | `/auth/me` | Fetch authenticated user profile | Bearer JWT |
| `PUT` | `/auth/profile` | Update profile details (full name, phone) | Bearer JWT |
| `PUT` | `/auth/privacy-settings` | Update safety network opt-in & GPS retention | Bearer JWT |
| `POST` | `/auth/change-password` | Update account password | Bearer JWT |

---

## 2. Emergency Contacts (`/contacts`)

| Method | Endpoint | Description | Auth Required |
|---|---|---|---|
| `GET` | `/contacts/` | List all emergency contacts for current user | Bearer JWT |
| `POST` | `/contacts/` | Add a new emergency contact (max 10) | Bearer JWT |
| `PUT` | `/contacts/{id}` | Update contact details and SOS alert toggle | Bearer JWT |
| `DELETE` | `/contacts/{id}` | Remove an emergency contact | Bearer JWT |

---

## 3. Journeys & Tracking (`/journeys`)

| Method | Endpoint | Description | Auth Required |
|---|---|---|---|
| `POST` | `/journeys/start` | Start tracking a new journey | Bearer JWT |
| `POST` | `/journeys/{id}/location`| Send location ping (lat, lon, speed, accuracy) | Bearer JWT |
| `POST` | `/journeys/{id}/end` | Conclude active journey and revoke shares | Bearer JWT |
| `GET` | `/journeys/active` | Get current user's active journey | Bearer JWT |
| `GET` | `/journeys/history` | Get past journeys (privacy minimized) | Bearer JWT |
| `POST` | `/journeys/{id}/share` | Generate temporary unguessable sharing token with TTL | Bearer JWT |
| `DELETE`| `/journeys/shares/{id}`| Revoke temporary sharing session | Bearer JWT |

---

## 4. Public Temporary Journey View (`/public`)

| Method | Endpoint | Description | Auth Required |
|---|---|---|---|
| `GET` | `/public/share/{token}` | Read-only live coordinates for trusted contact. Returns 410 if expired or revoked. | No (Token Auth) |

---

## 5. Emergency SOS (`/sos`)

| Method | Endpoint | Description | Auth Required |
|---|---|---|---|
| `POST` | `/sos/trigger` | Trigger active SOS, notify contacts, cache in Redis | Bearer JWT |
| `POST` | `/sos/{id}/cancel` | User aborts/cancels SOS | Bearer JWT |
| `GET` | `/sos/active` | Check active SOS status for current user | Bearer JWT |
| `GET` | `/sos/history` | User SOS history | Bearer JWT |

---

## 6. Incident Reporting (`/incidents`)

| Method | Endpoint | Description | Auth Required |
|---|---|---|---|
| `POST` | `/incidents/report` | Submit incident report (anonymous or identified) | Optional |
| `GET` | `/incidents/nearby` | Retrieve verified incidents within radius (km) | No |
| `GET` | `/incidents/{id}` | Get incident details | No |

---

## 7. Resources Discovery (`/resources`)

| Method | Endpoint | Description | Auth Required |
|---|---|---|---|
| `GET` | `/resources/emergency/nearby`| Proximity search for police, hospitals, safe havens | No |
| `GET` | `/resources/support` | List categorized legal, cybercrime, and crisis helplines | No |

---

## 8. Contextual Risk Intelligence (`/risk`)

| Method | Endpoint | Description | Auth Required |
|---|---|---|---|
| `POST` | `/risk/assess-area` | Run ML XGBoost model on coordinates; returns score, category, factors | No |
| `POST` | `/risk/assess-route` | Compare alternative routes and evaluate contextual risk | No |

---

## 9. Community Safety Network (`/network`)

| Method | Endpoint | Description | Auth Required |
|---|---|---|---|
| `POST` | `/network/ping` | Register ephemeral presence in 1.1km grid cell | Bearer JWT |
| `POST` | `/network/leave` | Withdraw from network presence | Bearer JWT |

---

## 10. Administration & Moderation (`/admin`)

| Method | Endpoint | Description | Required Role |
|---|---|---|---|
| `GET` | `/admin/overview` | Real-time database metrics & breakdown | ADMIN |
| `GET` | `/admin/incidents` | List all incidents with status filter | MODERATOR / ADMIN |
| `PUT` | `/admin/incidents/{id}/moderate`| Verify, reject, or resolve report | MODERATOR / ADMIN |
| `GET` | `/admin/sos` | List live and historical SOS dispatches | ADMIN |
| `PUT` | `/admin/sos/{id}/acknowledge` | Mark SOS acknowledged by dispatcher | ADMIN |
| `PUT` | `/admin/sos/{id}/resolve` | Resolve emergency dispatch with notes | ADMIN |
| `GET` | `/admin/resources/emergency` | List emergency stations | ADMIN |
| `POST` | `/admin/resources/emergency` | Add verified emergency facility | ADMIN |
| `DELETE`| `/admin/resources/emergency/{id}`| Remove facility | ADMIN |
| `GET` | `/admin/audit-logs` | Retrieve security and operations audit trail | ADMIN |
