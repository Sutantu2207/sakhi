/**
 * SAKHI Emergency Mesh — Binary & Framing Protocol Definition
 * Designed for ESP32 / ESP32-C3 / ESP32-S3 over ESP-NOW and BLE.
 * 
 * ZERO PII: Contains no user names, phone numbers, or static device IDs.
 * Transmits 128-bit rotating ephemeral identifiers with authenticated payloads.
 */

#ifndef SAKHI_MESH_PACKET_H
#define SAKHI_MESH_PACKET_H

#include <stdint.h>
#include <stdbool.h>

#define SAKHI_PROTOCOL_VERSION     1
#define SAKHI_MAX_PAYLOAD_SIZE     128
#define SAKHI_DEFAULT_TTL          5
#define SAKHI_EPHEMERAL_ID_LEN     16   // 128-bit rotating pseudorandom ID
#define SAKHI_AUTH_TAG_LEN         16   // 128-bit Poly1305 / HMAC-SHA256 tag
#define SAKHI_MESSAGE_ID_LEN       16   // UUIDv4 or 128-bit random

typedef enum {
    SAKHI_MSG_SOS              = 0x01,  // Critical Emergency SOS
    SAKHI_MSG_LOCATION_UPDATE  = 0x02,  // High-priority Location Ping
    SAKHI_MSG_CANCEL_SOS       = 0x03,  // User Cancellation / Safe Confirmation
    SAKHI_MSG_HEARTBEAT        = 0x04,  // Node Liveness Discovery
    SAKHI_MSG_GATEWAY_ACK      = 0x0A   // Gateway Ingestion Acknowledgment
} SakhiMessageType;

typedef enum {
    SAKHI_PRIORITY_CRITICAL    = 0x01,  // SOS alerts (preempts all queues)
    SAKHI_PRIORITY_HIGH        = 0x02,  // Active journey location telemetry
    SAKHI_PRIORITY_NORMAL      = 0x03   // Periodic beacon discovery
} SakhiPriority;

#pragma pack(push, 1)

/**
 * Compact 64-byte Emergency Packet Header
 */
typedef struct {
    uint8_t  protocol_version;                     // Protocol version (1)
    uint8_t  message_type;                         // SakhiMessageType enum
    uint8_t  priority;                             // SakhiPriority enum
    uint8_t  ttl;                                  // Remaining hop count (e.g. 5)
    uint8_t  hop_count;                            // Hops traversed so far
    uint8_t  sequence_number;                      // Monotonic anti-replay counter
    uint32_t unix_timestamp;                       // Epoch seconds UTC
    uint8_t  ephemeral_id[SAKHI_EPHEMERAL_ID_LEN]; // Rotating 128-bit pseudorandom ID
    uint8_t  message_id[SAKHI_MESSAGE_ID_LEN];     // Unique 128-bit packet UUID
    int32_t  latitude_scaled;                      // Latitude * 10,000,000 (1cm resolution)
    int32_t  longitude_scaled;                     // Longitude * 10,000,000 (1cm resolution)
    uint16_t accuracy_cm;                          // Accuracy in centimeters (e.g., 500 = 5.0m)
    uint16_t payload_len;                          // Encrypted payload length
} SakhiMeshHeader;

/**
 * Complete Frame including payload and authentication tag
 */
typedef struct {
    SakhiMeshHeader header;
    uint8_t payload[SAKHI_MAX_PAYLOAD_SIZE];
    uint8_t auth_tag[SAKHI_AUTH_TAG_LEN];          // Authenticated integrity tag
} SakhiMeshPacket;

#pragma pack(pop)

#endif // SAKHI_MESH_PACKET_H
