import 'package:flutter/material.dart';
import 'package:kltn_sharing_app/data/models/user_response_model.dart';
import 'package:kltn_sharing_app/data/services/user_api_service.dart';

class UserProvider extends ChangeNotifier {
  final UserApiService _userApiService = UserApiService();

  UserDto? _currentUser;
  UserDto? get currentUser => _currentUser;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Set authorization token from AuthProvider
  void setAuthToken(String accessToken) {
    _userApiService.setAuthToken(accessToken);
  }

  /// Load current user profile
  Future<void> loadCurrentUser() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _currentUser = await _userApiService.getCurrentUser();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      _errorMessage = errorMsg;
      print('[UserProvider] Error: $_errorMessage');
      notifyListeners();
    }
  }

  /// Load user by ID
  Future<UserDto?> getUserById(String userId) async {
    try {
      return await _userApiService.getUserById(userId);
    } catch (e) {
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      _errorMessage = errorMsg;
      print('[UserProvider] Error loading user $userId: $_errorMessage');
      return null;
    }
  }

  /// Refresh current user data
  Future<void> refreshCurrentUser() async {
    await loadCurrentUser();
  }

  /// Clear user data (on logout)
  void clearUser() {
    _currentUser = null;
    _errorMessage = null;
    notifyListeners();
  }
}
