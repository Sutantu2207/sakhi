# SAKHI Emergency Mesh — Architecture Specification

## 1. Overview & Product Positioning

The **SAKHI Emergency Mesh** is an experimental, infrastructure-independent emergency communication subsystem designed to relay critical emergency distress packets when standard 4G/5G cellular connectivity and Wi-Fi access are compromised, jammed, or unavailable.

> **Important Technical Positioning**:
> Sakhi uses standard internet connectivity (HTTPS over Cellular/Wi-Fi) as its primary communication path. The Emergency Mesh introduces an experimental low-power, short-message BLE + ESP32 + ESP-NOW layer to provide an **additional contingency path** for compact emergency alerts. It does not replace cellular data when cellular is available.

---

## 2. End-to-End Relay Topology

```
                  ┌──────────────────────┐
                  │     SAKHI CLOUD      │
                  │   FastAPI Backend    │
                  └──────────▲───────────┘
                             │
                       HTTPS Uplink
                             │
                  ┌──────────┴───────────┐
                  │    ESP32 GATEWAY     │
                  │ Wi-Fi AP / Hotspot   │
                  └──────────▲───────────┘
                             │
                        ESP-NOW 2.4GHz
                       (Direct MAC mesh)
                             │
                  ┌──────────┴───────────┐
                  │   ESP32 RELAY NODE   │
                  │ (Zero-Internet Hop)  │
                  └──────────▲───────────┘
                             │
                       Bluetooth LE
                     (GATT Peripheral)
                             │
                  ┌──────────┴───────────┐
                  │  SAKHI MOBILE CLIENT │
                  │  (Android / iOS App) │
                  └──────────────────────┘
```

---

## 3. Node Classifications

### 3.1 Mobile Client (Originator)
- Detects failure of cellular/Wi-Fi API calls during SOS activation.
- Generates a compact 64-byte binary packet containing a 128-bit rotating pseudorandom identifier (`ephemeral_id`), high-accuracy GPS coordinates, and monotonic sequence number.
- Transmits via BLE GATT write to nearby Sakhi Relay Nodes advertising Service UUID `0xFA10`.

### 3.2 Relay Node (ESP32 / ESP32-C3)
- Battery or solar-backed fixed/wearable node.
- No SIM card, internet connection, or cellular module required.
- Ingests BLE writes, validates protocol version and TTL.
- Maintains a 128-entry sliding ring buffer for anti-replay deduplication.
- Decrements TTL, increments hop count, and broadcasts over ESP-NOW channel 1.

### 3.3 Gateway Node (ESP32 / ESP32-S3)
- Located at police kiosks, metro stations, campus security desks, or mobile hotspots with internet access.
- Listens for ESP-NOW emergency packets.
- Translates binary frames into JSON payloads and issues HTTP POST to `/api/v1/network/mesh-gateway`.
- Dispatches gateway acknowledgment frames back into the mesh.
