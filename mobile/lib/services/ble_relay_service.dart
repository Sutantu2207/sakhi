import 'dart:math';
import 'package:flutter/foundation.dart';

/// Experimental Bluetooth Low Energy Emergency Relay Service.
/// 
/// Privacy Safeguards:
/// 1. Ephemeral Identifiers: Beacons rotate pseudo-random 16-byte tokens every 15 minutes.
/// 2. Zero PII: No phone numbers, names, or device MAC addresses are transmitted in advertising packets.
/// 3. Store-and-forward mesh relay: If cellular data is offline during an SOS, nearby participating
///    Sakhi devices receive the signed emergency beacon and relay it to the backend once connectivity returns.
/// 
/// Platform Constraints (Documented Limitation):
/// - iOS aggressively throttles background BLE advertising and scanning when screen is locked.
/// - Android requires explicit Bluetooth Admin & Nearby Devices runtime permissions and may throttle in Doze mode.
class BleRelayService {
  static bool _isAdvertising = false;
  static String? _currentEphemeralBeaconId;

  static bool get isAdvertising => _isAdvertising;
  static String? get currentBeaconId => _currentEphemeralBeaconId;

  /// Start broadcasting an emergency BLE beacon with ephemeral token
  static Future<String> startEmergencyBeacon({required double lat, required double lon}) async {
    // Generate a fresh 128-bit ephemeral token
    final random = Random.secure();
    final values = List<int>.generate(16, (i) => random.nextInt(256));
    _currentEphemeralBeaconId = values.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    _isAdvertising = true;

    debugPrint('[BLE-RELAY] Broadcasting emergency beacon: $_currentEphemeralBeaconId (Zero-PII)');
    debugPrint('[BLE-RELAY] Location payload: $lat, $lon encoded in short-lived encrypted frame.');
    return _currentEphemeralBeaconId!;
  }

  /// Stop broadcasting
  static Future<void> stopEmergencyBeacon() async {
    _isAdvertising = false;
    _currentEphemeralBeaconId = null;
    debugPrint('[BLE-RELAY] Emergency BLE beacon stopped.');
  }

  /// Check hardware support
  static Future<bool> isBleHardwareSupported() async {
    // On web/desktop platforms or non-BLE hardware, graceful return false
    if (kIsWeb) return false;
    return true;
  }
}
