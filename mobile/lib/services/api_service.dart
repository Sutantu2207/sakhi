import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import '../models/user.dart';
import '../models/contact.dart';
import '../models/journey.dart';
import '../models/sos.dart';
import '../models/incident.dart';
import '../models/resource.dart';
import '../models/risk.dart';

class ApiService {
  static String baseUrl = AppConstants.defaultBaseUrl;

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('sakhi_auth_token');
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sakhi_auth_token', token);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('sakhi_auth_token');
  }

  static Future<Map<String, String>> _headers({bool requiresAuth = true}) async {
    final headers = {'Content-Type': 'application/json'};
    if (requiresAuth) {
      final token = await getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  // --- AUTHENTICATION ---
  static Future<User> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: await _headers(requiresAuth: false),
      body: jsonEncode({
        'email': email,
        'password': password,
        'full_name': fullName,
        'phone': phone,
      }),
    );

    if (response.statusCode == 201) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      final err = jsonDecode(response.body);
      throw Exception(err['detail'] ?? 'Registration failed');
    }
  }

  static Future<User> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: await _headers(requiresAuth: false),
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await saveToken(data['access_token']);
      return await getMe();
    } else {
      final err = jsonDecode(response.body);
      throw Exception(err['detail'] ?? 'Invalid credentials');
    }
  }

  static Future<User> getMe() async {
    final response = await http.get(
      Uri.parse('$baseUrl/auth/me'),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Session expired');
    }
  }

  static Future<User> updatePrivacySettings({
    bool? safetyNetworkOptIn,
    int? locationRetentionDays,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/auth/privacy-settings'),
      headers: await _headers(),
      body: jsonEncode({
        if (safetyNetworkOptIn != null) 'safety_network_opt_in': safetyNetworkOptIn,
        if (locationRetentionDays != null) 'location_retention_days': locationRetentionDays,
      }),
    );

    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update privacy settings');
    }
  }

  // --- EMERGENCY CONTACTS ---
  static Future<List<EmergencyContact>> getContacts() async {
    final response = await http.get(
      Uri.parse('$baseUrl/contacts/'),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(response.body);
      return list.map((e) => EmergencyContact.fromJson(e)).toList();
    } else {
      throw Exception('Failed to fetch emergency contacts');
    }
  }

  static Future<EmergencyContact> addContact({
    required String name,
    required String phone,
    String? relationshipLabel,
    bool notifyOnSos = true,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/contacts/'),
      headers: await _headers(),
      body: jsonEncode({
        'name': name,
        'phone': phone,
        'relationship_label': relationshipLabel,
        'notify_on_sos': notifyOnSos,
        'priority_order': 1,
      }),
    );

    if (response.statusCode == 201) {
      return EmergencyContact.fromJson(jsonDecode(response.body));
    } else {
      final err = jsonDecode(response.body);
      throw Exception(err['detail'] ?? 'Failed to add contact');
    }
  }

  static Future<void> deleteContact(String contactId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/contacts/$contactId'),
      headers: await _headers(),
    );

    if (response.statusCode != 204) {
      throw Exception('Failed to delete contact');
    }
  }

  // --- JOURNEYS & TRACKING ---
  static Future<Journey> startJourney({
    String? destinationName,
    required double startLat,
    required double startLon,
    double? destLat,
    double? destLon,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/journeys/start'),
      headers: await _headers(),
      body: jsonEncode({
        'destination_name': destinationName,
        'start_lat': startLat,
        'start_lon': startLon,
        'destination_lat': destLat,
        'destination_lon': destLon,
      }),
    );

    if (response.statusCode == 201) {
      return Journey.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to start journey');
    }
  }

  static Future<Journey> sendLocationPing({
    required String journeyId,
    required double latitude,
    required double longitude,
    double? speed,
    double? accuracy,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/journeys/$journeyId/location'),
      headers: await _headers(),
      body: jsonEncode({
        'latitude': latitude,
        'longitude': longitude,
        'speed': speed,
        'accuracy': accuracy,
      }),
    );

    if (response.statusCode == 200) {
      return Journey.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update location');
    }
  }

  static Future<Journey> endJourney({
    required String journeyId,
    double? finalLat,
    double? finalLon,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/journeys/$journeyId/end'),
      headers: await _headers(),
      body: jsonEncode({
        'final_lat': finalLat,
        'final_lon': finalLon,
      }),
    );

    if (response.statusCode == 200) {
      return Journey.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to complete journey');
    }
  }

  static Future<Journey?> getActiveJourney() async {
    final response = await http.get(
      Uri.parse('$baseUrl/journeys/active'),
      headers: await _headers(),
    );

    if (response.statusCode == 200 && response.body.isNotEmpty && response.body != 'null') {
      return Journey.fromJson(jsonDecode(response.body));
    }
    return null;
  }

  static Future<JourneyShareInfo> shareJourney({
    required String journeyId,
    int durationMinutes = 30,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/journeys/$journeyId/share'),
      headers: await _headers(),
      body: jsonEncode({'duration_minutes': durationMinutes}),
    );

    if (response.statusCode == 200) {
      return JourneyShareInfo.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to generate sharing token');
    }
  }

  // --- EMERGENCY SOS ---
  static Future<SOSEvent> triggerSOS({
    required double latitude,
    required double longitude,
    String? addressApprox,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/sos/trigger'),
      headers: await _headers(),
      body: jsonEncode({
        'latitude': latitude,
        'longitude': longitude,
        'address_approx': addressApprox,
      }),
    );

    if (response.statusCode == 201) {
      return SOSEvent.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to trigger emergency SOS');
    }
  }

  static Future<SOSEvent> cancelSOS({
    required String sosId,
    String reason = 'Accidental trigger',
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/sos/$sosId/cancel'),
      headers: await _headers(),
      body: jsonEncode({'reason': reason}),
    );

    if (response.statusCode == 200) {
      return SOSEvent.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to cancel SOS');
    }
  }

  static Future<SOSEvent?> getActiveSOS() async {
    final response = await http.get(
      Uri.parse('$baseUrl/sos/active'),
      headers: await _headers(),
    );

    if (response.statusCode == 200 && response.body.isNotEmpty && response.body != 'null') {
      return SOSEvent.fromJson(jsonDecode(response.body));
    }
    return null;
  }

  // --- INCIDENTS ---
  static Future<Incident> reportIncident({
    required String category,
    required String severity,
    required String description,
    required double latitude,
    required double longitude,
    bool isAnonymous = false,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/incidents/report'),
      headers: await _headers(requiresAuth: !isAnonymous),
      body: jsonEncode({
        'category': category,
        'severity': severity,
        'description': description,
        'latitude': latitude,
        'longitude': longitude,
        'is_anonymous': isAnonymous,
      }),
    );

    if (response.statusCode == 201) {
      return Incident.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to report incident');
    }
  }

  static Future<List<Incident>> getNearbyIncidents({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/incidents/nearby?latitude=$latitude&longitude=$longitude&radius_km=$radiusKm'),
      headers: await _headers(requiresAuth: false),
    );

    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(response.body);
      return list.map((e) => Incident.fromJson(e)).toList();
    } else {
      return [];
    }
  }

  // --- RESOURCES ---
  static Future<List<EmergencyResource>> getNearbyEmergencyResources({
    required double latitude,
    required double longitude,
    double radiusKm = 10.0,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/resources/emergency/nearby?latitude=$latitude&longitude=$longitude&radius_km=$radiusKm'),
      headers: await _headers(requiresAuth: false),
    );

    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(response.body);
      return list.map((e) => EmergencyResource.fromJson(e)).toList();
    } else {
      return [];
    }
  }

  static Future<List<SupportResource>> getSupportResources() async {
    final response = await http.get(
      Uri.parse('$baseUrl/resources/support'),
      headers: await _headers(requiresAuth: false),
    );

    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(response.body);
      return list.map((e) => SupportResource.fromJson(e)).toList();
    } else {
      return [];
    }
  }

  // --- RISK ASSESSMENT ---
  static Future<AreaRisk> assessAreaRisk({
    required double latitude,
    required double longitude,
    double radiusKm = 1.0,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/risk/assess-area'),
      headers: await _headers(requiresAuth: false),
      body: jsonEncode({
        'latitude': latitude,
        'longitude': longitude,
        'radius_km': radiusKm,
      }),
    );

    if (response.statusCode == 200) {
      return AreaRisk.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to assess area risk');
    }
  }

  // --- SAFETY NETWORK ---
  static Future<Map<String, dynamic>> sendNetworkPing({
    required double latitude,
    required double longitude,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/network/ping'),
      headers: await _headers(),
      body: jsonEncode({'latitude': latitude, 'longitude': longitude}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to sync with safety network');
    }
  }
}
