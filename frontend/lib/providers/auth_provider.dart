import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/user.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  User? _currentUser;
  bool _isLoading = false;
  String? _error;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;
  bool get isWorker => _currentUser?.isWorker ?? false;
  bool get isContractor => _currentUser?.isContractor ?? false;

  // Check if user is already logged in
  Future<bool> checkAuthStatus() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await _apiService.getToken();
      if (token != null) {
        _currentUser = await _apiService.getCurrentUser();
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _error = e.toString();
      await _apiService.deleteToken();
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // Login
  Future<bool> login({
  required String username,
  required String password,
}) async {
  _isLoading = true;
  _error = null;
  notifyListeners();

  try {
    // 1) Login -> saves token already in ApiService
    await _apiService.login(
      username: username,
      password: password,
    );

    // 2) Fetch logged-in user
    _currentUser = await _apiService.getCurrentUser();

    _isLoading = false;
    notifyListeners();
    return true;
  } catch (e) {
    _error = e.toString().replaceAll('Exception: ', '');
    _isLoading = false;
    notifyListeners();
    return false;
  }
}

  // Register
  Future<bool> register({
  required String username,
  required String email,
  required String password,
  required String fullName,
  required String role,
  String? phone,
}) async {
  _isLoading = true;
  _error = null;
  notifyListeners();

  try {
    // 1) Register -> saves token already in ApiService
    await _apiService.register(
      username: username,
      email: email,
      password: password,
      fullName: fullName,
      role: role,
      phone: phone,
    );

    // 2) Fetch logged-in user
    _currentUser = await _apiService.getCurrentUser();

    _isLoading = false;
    notifyListeners();
    return true;
  } catch (e) {
    _error = e.toString().replaceAll('Exception: ', '');
    _isLoading = false;
    notifyListeners();
    return false;
  }
}

  // Logout
  Future<void> logout() async {
    await _apiService.logout();
    _currentUser = null;
    _error = null;
    notifyListeners();
  }

  // Update current user info
  void updateUser(User user) {
    _currentUser = user;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
