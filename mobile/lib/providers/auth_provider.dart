import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = true;
  String? _errorMessage;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;
  String? get errorMessage => _errorMessage;

  AuthProvider() {
    checkSession();
  }

  Future<void> checkSession() async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await ApiService.getToken();
      if (token != null) {
        _currentUser = await ApiService.getMe();
      }
    } catch (e) {
      _currentUser = null;
      await ApiService.clearToken();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await ApiService.login(email: email, password: password);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String email, String password, String fullName, String? phone) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await ApiService.register(email: email, password: password, fullName: fullName, phone: phone);
      // Auto-login after registration
      return await login(email, password);
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> updatePrivacySettings({bool? safetyNetworkOptIn, int? locationRetentionDays}) async {
    try {
      _currentUser = await ApiService.updatePrivacySettings(
        safetyNetworkOptIn: safetyNetworkOptIn,
        locationRetentionDays: locationRetentionDays,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating privacy settings: $e');
    }
  }

  Future<void> logout() async {
    await ApiService.clearToken();
    _currentUser = null;
    notifyListeners();
  }
}
