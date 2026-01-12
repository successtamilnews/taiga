import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _token;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null && _token != null;
  String? get token => _token;

  final ApiService _apiService = ApiService();

  Future<bool> checkAuthStatus() async {
    try {
      _isLoading = true;
      notifyListeners();

      final token = await _apiService.getStoredToken();
      if (token != null) {
        _token = token;
        final userData = await _apiService.getCurrentUser();
        _user = User.fromJson(userData);
        return true;
      }
      return false;
    } catch (e) {
      print('Auth check failed: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await _apiService.login(email, password);
      _token = response['token'];
      _user = User.fromJson(response['user']);
      
      await _apiService.saveToken(_token!);
      
      return true;
    } catch (e) {
      print('Login failed: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register(Map<String, dynamic> userData) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await _apiService.register(userData);
      _token = response['token'];
      _user = User.fromJson(response['user']);
      
      await _apiService.saveToken(_token!);
      
      return true;
    } catch (e) {
      print('Registration failed: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    try {
      await _apiService.logout();
    } catch (e) {
      print('Logout failed: $e');
    } finally {
      _user = null;
      _token = null;
      await _apiService.clearToken();
      notifyListeners();
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> userData) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await _apiService.updateProfile(userData);
      _user = User.fromJson(response);
      
      return true;
    } catch (e) {
      print('Profile update failed: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}