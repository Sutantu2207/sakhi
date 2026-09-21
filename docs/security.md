# SAKHI — Security & Cryptographic Controls

## 1. Authentication & Token Management
- **Password Hashing**: Cryptographic one-way password hashing using `bcrypt` with automatic salt generation. Plaintext passwords are never stored or logged.
- **JWT Authorization**: Cryptographically signed JSON Web Tokens (`HS256` in development, configurable `RS256` for production asymmetric key pairs).
- **Session Expiry**: Default 7-day token lifetime, revocable via active sessions management.

---

## 2. Role-Based Access Control (RBAC)
The API strictly enforces role checks at the router layer using FastAPI dependencies:
- `USER`: Regular mobile traveler. Can only view and mutate their own journeys, contacts, and personal SOS events.
- `MODERATOR`: Authorized to view the incident queue, verify community reports, reject duplicates, and annotate verification notes.
- `ADMIN`: Full operational oversight. Can acknowledge and resolve emergency SOS events, create verified emergency infrastructure points, and inspect compliance audit logs.

Frontend conditional rendering is never relied on for security; every API route enforces server-side claims validation.

---

## 3. Threat Mitigation Matrix

| Potential Vulnerability | Mitigation Strategy Implemented in SAKHI |
|---|---|
| **SQL Injection** | SQLAlchemy ORM parameterized queries; raw concatenated SQL is prohibited. |
| **Brute Force on Auth / SOS** | Redis-backed token rate limiting and account lockout after repeated failures. |
| **Unauthorized SOS Resolution**| SOS resolution endpoints require valid `ADMIN` JWT authorization. |
| **Public Coordinate Exposure** | Public sharing endpoints require a 192-bit unguessable ephemeral token; returns 410 upon revocation or TTL expiration. |
| **PII Leakage in Logs** | Audit log service logs only high-level actions (`USER_LOGIN`, `SOS_TRIGGERED`); passwords and raw tokens are excluded. |
