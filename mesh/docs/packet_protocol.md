# SAKHI Emergency Mesh — Packet Protocol Specification

## 1. Frame Layout (64-byte Header + Encrypted Payload)

```
0                   1                   2                   3
0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|  Proto Version|  Message Type |    Priority   |      TTL      |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|   Hop Count   |Sequence Number|       Unix Timestamp UTC      |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                   128-bit Ephemeral Beacon                    |
|             (16 Bytes — Rotates Every 15 Minutes)             |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                      128-bit Message ID                       |
|               (16 Bytes — Anti-Replay UUIDv4)                 |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|              Latitude (Signed int32 * 10^7)                   |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|             Longitude (Signed int32 * 10^7)                   |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|          Accuracy (cm)        |       Payload Length          |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|               Encrypted Payload (Max 128 Bytes)               |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|             128-bit Poly1305 / HMAC Auth Tag                  |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
```

## 2. Privacy & Anti-Surveillance Guarantees
- **Zero PII**: No name, phone number, IMEI, MAC address, or static ID is ever transmitted over the air.
- **Rotating Ephemeral Identifiers**: Generated using pseudorandom cryptographically secure seed, rotated every 15 minutes.
- **Deduplication Sliding Window**: Prevents replay attacks and packet looping.
- **Strict TTL Expiration**: Default TTL = 5 hops. Packets exceeding TTL are discarded immediately.
