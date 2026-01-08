import 'package:flutter/material.dart';
import 'package:kltn_sharing_app/data/models/user_response_model.dart';
import 'package:kltn_sharing_app/data/models/transaction_stats_model.dart';
import 'package:kltn_sharing_app/data/services/user_api_service.dart';
import 'package:kltn_sharing_app/data/services/transaction_api_service.dart';

class UserProvider extends ChangeNotifier {
  final UserApiService _userApiService = UserApiService();
  final TransactionApiService _transactionApiService = TransactionApiService();

  UserDto? _currentUser;
  UserDto? get currentUser => _currentUser;

  TransactionStats? _transactionStats;
  TransactionStats? get transactionStats => _transactionStats;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isLoadingStats = false;
  bool get isLoadingStats => _isLoadingStats;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _statsErrorMessage;
  String? get statsErrorMessage => _statsErrorMessage;

  /// Set authorization token from AuthProvider
  void setAuthToken(String accessToken) {
    _userApiService.setAuthToken(accessToken);
    _transactionApiService.setAuthToken(accessToken);
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

  /// Update FCM token on backend
  Future<void> updateFCMToken({
    required String userId,
    required String fcmToken,
  }) async {
    try {
      await _userApiService.updateFCMToken(
        userId: userId,
        fcmToken: fcmToken,
      );
    } catch (e) {
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      _errorMessage = errorMsg;
      print('[UserProvider] Error updating FCM token: $_errorMessage');
      rethrow;
    }
  }

  /// Delete FCM token on logout
  Future<void> deleteFCMToken() async {
    try {
      await _userApiService.deleteFCMToken();
    } catch (e) {
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      print('[UserProvider] Error deleting FCM token: $errorMsg');
      // Don't rethrow - logout should succeed even if delete fails
    }
  }

  /// Load transaction statistics for current user
  Future<void> loadTransactionStats() async {
    try {
      _isLoadingStats = true;
      _statsErrorMessage = null;
      notifyListeners();

      final statsMap = await _transactionApiService.getTransactionStats();
      _transactionStats = TransactionStats.fromJson(statsMap);

      _isLoadingStats = false;
      notifyListeners();
    } catch (e) {
      _isLoadingStats = false;
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      _statsErrorMessage = errorMsg;
      print(
          '[UserProvider] Error loading transaction stats: $_statsErrorMessage');
      notifyListeners();
    }
  }
}
