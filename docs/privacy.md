# SAKHI — Privacy Architecture & Threat Model

Privacy is a non-negotiable architectural foundation of SAKHI. The platform is designed around the core principle of **Data Minimization, Ephemeral Tracking, and Zero Unnecessary Exposure**.

---

## 1. Core Privacy Tenets

### 1.1 Ephemeral Location Tracking
- Real-time GPS coordinates are collected **only while a journey or SOS is explicitly active**.
- Once a journey concludes, continuous tracking immediately ceases.
- Detailed historical breadcrumbs are not stored permanently. Only summarized metrics (start time, end time, total distance, maximum risk tier encountered) are retained.

### 1.2 Time-Limited Temporary Journey Sharing
- Sharing links are governed by high-entropy, cryptographically secure 192-bit tokens (`secrets.token_urlsafe`).
- Tokens include a mandatory Time-To-Live (15 min, 30 min, 60 min) after which access returns HTTP `410 Gone`.
- Users can revoke active sharing sessions with a single tap at any time.

### 1.3 Approximate Community Presence (Zero Identity Broadcast)
- The Community Safety Network uses coarse 2-decimal spatial grid cells (~1.1 km resolution).
- Nearby users are presented strictly as an anonymous count (e.g. `12 participants nearby`).
- Zero personal identifiers, names, phone numbers, exact coordinates, or movement vectors are shared across participants.
- Network presence records in Redis auto-expire after 10 minutes (600s TTL).

### 1.4 Anonymous Incident Reporting
- Users can report safety hazards, poor lighting, or harassment completely anonymously.
- When `is_anonymous` is toggled, the reporter's user ID is scrubbed (`reporter_id = NULL`), preventing any link between the report and user profile.

### 1.5 Configurable Retention & Account Purge
- Users can select their location data retention policy (3, 7, 14, or 30 days) from the Privacy Dashboard.
- Complete account deletion permanently cascades and deletes all associated emergency contacts, journey sessions, and user records.
