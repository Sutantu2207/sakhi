import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/constants.dart';

enum MeshStatus {
  standby,
  scanning,
  relayAvailable,
  transmitting,
  relayedToCloud,
  offline,
}

class MeshRelayTelemetry {
  final String messageId;
  final String ephemeralId;
  final int hopCount;
  final int ttl;
  final String gatewayId;
  final DateTime timestamp;
  final bool deliveredToCloud;

  MeshRelayTelemetry({
    required this.messageId,
    required this.ephemeralId,
    required this.hopCount,
    required this.ttl,
    required this.gatewayId,
    required this.timestamp,
    required this.deliveredToCloud,
  });
}

class EmergencyMeshService {
  static final EmergencyMeshService _instance = EmergencyMeshService._internal();
  factory EmergencyMeshService() => _instance;
  EmergencyMeshService._internal();

  MeshStatus _currentStatus = MeshStatus.relayAvailable;
  MeshStatus get currentStatus => _currentStatus;

  final StreamController<MeshStatus> _statusController = StreamController<MeshStatus>.broadcast();
  Stream<MeshStatus> get statusStream => _statusController.stream;

  String _generateEphemeralId() {
    final random = Random.secure();
    final bytes = List<int>.generate(8, (_) => random.nextInt(256));
    return 'eph-${bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join()}';
  }

  String _generateMessageId() {
    final random = Random.secure();
    final bytes = List<int>.generate(8, (_) => random.nextInt(256));
    return 'pkt-${bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join()}';
  }

  /// Transmits a compact zero-PII emergency packet to nearby ESP32 Mesh Gateway / Relay
  Future<MeshRelayTelemetry?> transmitEmergencyMeshSOS({
    required double latitude,
    required double longitude,
    double accuracyMeters = 10.0,
  }) async {
    _updateStatus(MeshStatus.transmitting);

    final msgId = _generateMessageId();
    final ephId = _generateEphemeralId();
    final now = DateTime.now().toUtc();

    final packetPayload = {
      'version': 1,
      'message_id': msgId,
      'ephemeral_id': ephId,
      'message_type': 'SOS',
      'timestamp': now.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'accuracy_meters': accuracyMeters,
      'sequence': 1,
      'ttl': 5,
      'hop_count': 1,
      'priority': 'EMERGENCY',
      'gateway_id': 'ESP32-GW-LOCAL',
    };

    try {
      // In mobile app, this posts to the local mesh gateway or API gateway bridge
      final url = Uri.parse('${AppConstants.defaultBaseUrl}/network/mesh-gateway');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(packetPayload),
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200 || response.statusCode == 201) {
        _updateStatus(MeshStatus.relayedToCloud);
        return MeshRelayTelemetry(
          messageId: msgId,
          ephemeralId: ephId,
          hopCount: 2,
          ttl: 4,
          gatewayId: 'ESP32-GW-LOCAL',
          timestamp: now,
          deliveredToCloud: true,
        );
      }
    } catch (e) {
      debugPrint('[MESH] Gateway direct bridge offline: $e');
    }

    _updateStatus(MeshStatus.relayAvailable);
    return MeshRelayTelemetry(
      messageId: msgId,
      ephemeralId: ephId,
      hopCount: 1,
      ttl: 5,
      gatewayId: 'ESP32-RELAY-STANDBY',
      timestamp: now,
      deliveredToCloud: false,
    );
  }

  void _updateStatus(MeshStatus status) {
    _currentStatus = status;
    _statusController.add(status);
  }

  void dispose() {
    _statusController.close();
  }
}
