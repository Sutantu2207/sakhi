import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/sos.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import '../services/ble_relay_service.dart';

class SOSProvider extends ChangeNotifier {
  SOSEvent? _activeSOS;
  bool _isCountingDown = false;
  int _countdownSeconds = 5;
  Timer? _countdownTimer;

  SOSEvent? get activeSOS => _activeSOS;
  bool get isCountingDown => _isCountingDown;
  int get countdownSeconds => _countdownSeconds;
  bool get isSOSActive => _activeSOS != null && (_activeSOS!.status == 'ACTIVE' || _activeSOS!.status == 'ACKNOWLEDGED');

  SOSProvider() {
    checkActiveSOS();
  }

  Future<void> checkActiveSOS() async {
    try {
      _activeSOS = await ApiService.getActiveSOS();
      notifyListeners();
    } catch (e) {
      debugPrint('Check active SOS error: $e');
    }
  }

  /// Start 5-second countdown with immediate cancel option
  void initiateSOSCountdown({required VoidCallback onComplete}) {
    _isCountingDown = true;
    _countdownSeconds = 5;
    notifyListeners();

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdownSeconds > 1) {
        _countdownSeconds--;
        notifyListeners();
      } else {
        timer.cancel();
        _isCountingDown = false;
        notifyListeners();
        triggerSOSImmediately();
        onComplete();
      }
    });
  }

  void cancelCountdown() {
    _countdownTimer?.cancel();
    _isCountingDown = false;
    _countdownSeconds = 5;
    notifyListeners();
  }

  Future<bool> triggerSOSImmediately() async {
    try {
      final pos = await LocationService.getCurrentLocation();
      _activeSOS = await ApiService.triggerSOS(
        latitude: pos.latitude,
        longitude: pos.longitude,
        addressApprox: 'GPS Emergency Beacon Captured',
      );

      // Start experimental BLE beacon relay
      try {
        await BleRelayService.startEmergencyBeacon(lat: pos.latitude, lon: pos.longitude);
      } catch (_) {}

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Trigger SOS error: $e');
      return false;
    }
  }

  Future<bool> cancelActiveSOS({String reason = 'Accidental trigger'}) async {
    if (_activeSOS == null) return false;
    try {
      await ApiService.cancelSOS(sosId: _activeSOS!.id, reason: reason);
      await BleRelayService.stopEmergencyBeacon();
      _activeSOS = null;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Cancel active SOS error: $e');
      return false;
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }
}
