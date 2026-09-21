import 'package:flutter/foundation.dart';
import '../models/risk.dart';
import '../models/incident.dart';
import '../models/resource.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';

class SafetyProvider extends ChangeNotifier {
  AreaRisk? _currentRisk;
  List<Incident> _nearbyIncidents = [];
  List<EmergencyResource> _emergencyResources = [];
  List<SupportResource> _supportResources = [];
  int _nearbyNetworkCount = 0;
  bool _isLoading = false;

  AreaRisk? get currentRisk => _currentRisk;
  List<Incident> get nearbyIncidents => _nearbyIncidents;
  List<EmergencyResource> get emergencyResources => _emergencyResources;
  List<SupportResource> get supportResources => _supportResources;
  int get nearbyNetworkCount => _nearbyNetworkCount;
  bool get isLoading => _isLoading;

  SafetyProvider() {
    refreshSafetyContext();
  }

  Future<void> refreshSafetyContext() async {
    _isLoading = true;
    notifyListeners();

    try {
      final pos = await LocationService.getCurrentLocation();

      // Parallel fetch of contextual risk, verified incidents, and nearby emergency help
      final results = await Future.wait([
        ApiService.assessAreaRisk(latitude: pos.latitude, longitude: pos.longitude),
        ApiService.getNearbyIncidents(latitude: pos.latitude, longitude: pos.longitude, radiusKm: 5.0),
        ApiService.getNearbyEmergencyResources(latitude: pos.latitude, longitude: pos.longitude, radiusKm: 10.0),
        ApiService.getSupportResources(),
      ]);

      _currentRisk = results[0] as AreaRisk;
      _nearbyIncidents = results[1] as List<Incident>;
      _emergencyResources = results[2] as List<EmergencyResource>;
      _supportResources = results[3] as List<SupportResource>;

      // Try syncing safety network presence
      try {
        final netStatus = await ApiService.sendNetworkPing(latitude: pos.latitude, longitude: pos.longitude);
        _nearbyNetworkCount = netStatus['nearby_participants_count'] as int? ?? 0;
      } catch (_) {}

    } catch (e) {
      debugPrint('Safety context fetch note: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> submitIncident({
    required String category,
    required String severity,
    required String description,
    required double latitude,
    required double longitude,
    bool isAnonymous = false,
  }) async {
    try {
      await ApiService.reportIncident(
        category: category,
        severity: severity,
        description: description,
        latitude: latitude,
        longitude: longitude,
        isAnonymous: isAnonymous,
      );
      await refreshSafetyContext();
      return true;
    } catch (e) {
      debugPrint('Submit incident error: $e');
      return false;
    }
  }
}
