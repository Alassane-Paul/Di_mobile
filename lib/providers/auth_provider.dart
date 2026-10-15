import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../models/user.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  User? _currentUser;
  bool _isLoading = false;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;

  Future<void> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _apiService.login(username, password);
      await loadProfile();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> register(String username, String email, String password, String displayName) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _apiService.register(username, email, password, displayName);
      await loadProfile();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> loadProfile() async {
    try {
      _currentUser = await _apiService.getProfile();
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    try {
      await _apiService.updateProfile(data);
      await loadProfile();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> checkAuth() async {
    final isAuth = await _apiService.checkAuth();
    if (isAuth) {
      await loadProfile();
    }
  }

  Future<void> logout() async {
    await _apiService.logout();
    _currentUser = null;
    notifyListeners();
  }

  Future<Map<String, dynamic>> uploadFile(String filePath) async {
    return await _apiService.uploadFile(filePath);
  }

  Future<Map<String, dynamic>> uploadFileBytes(String filename, List<int> bytes) async {
    return await _apiService.uploadFileBytes(filename, bytes);
  }
}
