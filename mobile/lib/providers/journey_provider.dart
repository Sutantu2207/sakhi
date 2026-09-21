import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/journey.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';

class JourneyProvider extends ChangeNotifier {
  Journey? _activeJourney;
  JourneyShareInfo? _activeShare;
  bool _isTracking = false;
  Timer? _pingTimer;

  Journey? get activeJourney => _activeJourney;
  JourneyShareInfo? get activeShare => _activeShare;
  bool get isTracking => _isTracking;

  JourneyProvider() {
    checkActiveJourney();
  }

  Future<void> checkActiveJourney() async {
    try {
      _activeJourney = await ApiService.getActiveJourney();
      if (_activeJourney != null) {
        _startPingTimer();
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Check active journey error: $e');
    }
  }

  Future<bool> startJourney({String? destinationName, double? destLat, double? destLon}) async {
    try {
      final pos = await LocationService.getCurrentLocation();
      _activeJourney = await ApiService.startJourney(
        destinationName: destinationName,
        startLat: pos.latitude,
        startLon: pos.longitude,
        destLat: destLat,
        destLon: destLon,
      );
      _startPingTimer();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Start journey error: $e');
      return false;
    }
  }

  void _startPingTimer() {
    _isTracking = true;
    _pingTimer?.cancel();
    // Ping every 30 seconds to preserve battery while maintaining safety
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (_activeJourney == null) {
        timer.cancel();
        return;
      }
      try {
        final pos = await LocationService.getCurrentLocation();
        _activeJourney = await ApiService.sendLocationPing(
          journeyId: _activeJourney!.id,
          latitude: pos.latitude,
          longitude: pos.longitude,
          speed: pos.speed,
          accuracy: pos.accuracy,
        );
        notifyListeners();
      } catch (e) {
        debugPrint('Ping location error: $e');
      }
    });
  }

  Future<bool> createShare({int durationMinutes = 30}) async {
    if (_activeJourney == null) return false;
    try {
      _activeShare = await ApiService.shareJourney(
        journeyId: _activeJourney!.id,
        durationMinutes: durationMinutes,
      );
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Share journey error: $e');
      return false;
    }
  }

  Future<bool> endJourney() async {
    if (_activeJourney == null) return false;
    try {
      final pos = await LocationService.getCurrentLocation();
      _pingTimer?.cancel();
      _isTracking = false;
      await ApiService.endJourney(
        journeyId: _activeJourney!.id,
        finalLat: pos.latitude,
        finalLon: pos.longitude,
      );
      _activeJourney = null;
      _activeShare = null;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('End journey error: $e');
      return false;
    }
  }

  @override
  void dispose() {
    _pingTimer?.cancel();
    super.dispose();
  }
}
