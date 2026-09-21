# SAKHI — Experimental BLE Emergency Relay Specification

## 1. Overview & Problem Scope

In scenarios where a victim encounters cellular dead zones, SIM card loss, or network throttling during an emergency:
- Standard HTTPS SOS requests fail to reach backend servers immediately.
- The **BLE Emergency Relay** acts as an experimental secondary mesh mechanism to broadcast an ephemeral emergency token to nearby participating devices.

---

## 2. Privacy & Cryptographic Architecture

### 2.1 Zero-PII Advertising Packets
- BLE broadcast packets **never contain**:
  - User name
  - Phone number
  - Device MAC address
  - Account ID
- The advertising payload consists solely of:
  - `0x5341` (Sakhi Service UUID header)
  - `16-byte Ephemeral Rotating Beacon ID`
  - Encrypted compact coordinate delta and timestamp nonce

### 2.2 Rotating Ephemeral Identifiers
- The beacon identifier rotates pseudo-randomly every 15 minutes.
- Prevents third-party physical tracking or passive profiling of the user.

---

## 3. Store-and-Forward Mesh Relay Protocol

```
[Victim Device - Offline]
        |
        | (BLE Broadcast: Ephemeral Token + Encrypted Location)
        v
[Nearby Participating Sakhi Device]
        |
        | (Store packet in local secure buffer)
        v
[Device Connects to Internet / Cellular]
        |
        | (POST /api/v1/sos/relay-beacon)
        v
[Sakhi Central Backend]
        |
        | (Decrypts payload, dispatches alert to trusted contacts & dispatchers)
        v
[Emergency Services / Contacts Alerted]
```

---

## 4. Platform Limitations & Non-Blocker Isolation

### Real-World Operating System Constraints:
1. **iOS Background Execution Limits**: Apple CoreBluetooth severely limits background peripheral advertising when the app is backgrounded or screen is locked. Advertising frequency drops and service UUIDs are moved to overflow areas.
2. **Android Doze Mode**: Power management optimizations throttle BLE scanning intervals unless foreground service with battery optimization exclusion is granted.
3. **Hardware Dependency**: BLE transmission requires Bluetooth 4.2+ with peripheral mode support.

### Production Guardrail:
The core SAKHI platform **does NOT depend on BLE for its primary operation**. BLE is implemented as a gracefully isolated fallback module (`mobile/lib/services/ble_relay_service.dart`).
