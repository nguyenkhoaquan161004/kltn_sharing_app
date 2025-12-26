import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kltn_sharing_app/data/models/auth_request_model.dart';
import 'package:kltn_sharing_app/data/services/auth_api_service.dart';

/// Provider for managing authentication state and tokens
class AuthProvider extends ChangeNotifier {
  final AuthApiService _authApiService;
  late SharedPreferences _prefs;

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _tokenExpiresAtKey = 'token_expires_at';
  static const String _usernameKey = 'username';
  static const int _tokenExpiryBufferSeconds =
      60; // Refresh 1 min before expiry

  String? _accessToken;
  String? _refreshToken;
  String? _username;
  bool _isLoading = false;
  String? _errorMessage;
  DateTime? _tokenExpiresAt;
  bool _isRefreshing = false; // Prevent multiple refresh attempts

  AuthProvider({required AuthApiService authApiService})
      : _authApiService = authApiService {
    _init();
  }

  // Getters
  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  String? get username => _username;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _accessToken != null && _accessToken!.isNotEmpty;

  /// Initialize provider and load saved tokens
  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    _loadTokens();
  }

  /// Load tokens from shared preferences
  void _loadTokens() {
    _accessToken = _prefs.getString(_accessTokenKey);
    _refreshToken = _prefs.getString(_refreshTokenKey);
    _username = _prefs.getString(_usernameKey);

    final expiresAtStr = _prefs.getString(_tokenExpiresAtKey);
    if (expiresAtStr != null) {
      _tokenExpiresAt = DateTime.tryParse(expiresAtStr);
    }

    if (_accessToken != null) {
      _authApiService.setAuthToken(_accessToken!);
    }

    notifyListeners();
  }

  /// Save tokens to shared preferences
  Future<void> _saveTokens(
    String accessToken,
    String refreshToken,
    int expiresInSeconds,
    String? username,
  ) async {
    final expiresAt = DateTime.now().add(Duration(seconds: expiresInSeconds));

    // IMPORTANT: Save refreshToken - required for future token refresh!
    await _prefs.setString(_accessTokenKey, accessToken);
    await _prefs.setString(_refreshTokenKey, refreshToken);
    await _prefs.setString(_tokenExpiresAtKey, expiresAt.toIso8601String());
    if (username != null) {
      await _prefs.setString(_usernameKey, username);
    }

    _accessToken = accessToken;
    _refreshToken = refreshToken;
    _username = username;
    _tokenExpiresAt = expiresAt;
    _authApiService.setAuthToken(accessToken);

    print('[AuthProvider] ✅ Tokens saved to SharedPreferences');
    print('[AuthProvider] - Access Token: ${accessToken.substring(0, 20)}...');
    print(
        '[AuthProvider] - Refresh Token: ${refreshToken.substring(0, 20)}...');
    print('[AuthProvider] - Expires At: $expiresAt');
    print('[AuthProvider] - Username: $username');

    notifyListeners();
  }

  /// Clear all tokens
  Future<void> _clearTokens() async {
    await _prefs.remove(_accessTokenKey);
    await _prefs.remove(_refreshTokenKey);
    await _prefs.remove(_tokenExpiresAtKey);
    await _prefs.remove(_usernameKey);

    _accessToken = null;
    _refreshToken = null;
    _username = null;
    _tokenExpiresAt = null;
    _isRefreshing = false; // Reset refresh flag
    _authApiService.removeAuthToken();

    notifyListeners();
  }

  /// Check if access token needs refresh (expires within buffer time)
  bool _shouldRefreshToken() {
    if (_tokenExpiresAt == null || _refreshToken == null) {
      return false;
    }

    final bufferTime =
        DateTime.now().add(Duration(seconds: _tokenExpiryBufferSeconds));
    return _tokenExpiresAt!.isBefore(bufferTime);
  }

  /// Refresh access token using refresh token
  Future<bool> refreshAccessToken() async {
    // Prevent multiple simultaneous refresh attempts
    if (_isRefreshing) {
      print('[AuthProvider] ⏳ Token refresh already in progress, waiting...');
      // Wait a bit and return the current token state
      await Future.delayed(Duration(milliseconds: 500));
      return _accessToken != null && _accessToken!.isNotEmpty;
    }

    if (_refreshToken == null || _refreshToken!.isEmpty) {
      print('[AuthProvider] ❌ No refresh token available in memory');
      return false;
    }

    _isRefreshing = true;

    try {
      print('[AuthProvider] 🔄 Refreshing access token using refresh token...');
      final request = RefreshTokenRequest(refreshToken: _refreshToken!);
      final tokenResponse = await _authApiService.refreshToken(request);

      // Check if backend returned valid refresh token
      if (tokenResponse.refreshToken.isEmpty) {
        print('[AuthProvider] ❌ Backend returned empty refresh token');
        await _clearTokens();
        _isRefreshing = false;
        return false;
      }

      print('[AuthProvider] ✅ Got new tokens from backend');
      print(
          '[AuthProvider] New refresh token: ${tokenResponse.refreshToken.substring(0, 20)}...');

      await _saveTokens(
        tokenResponse.accessToken,
        tokenResponse.refreshToken,
        tokenResponse.expiresIn,
        _username,
      );

      print('[AuthProvider] ✅ Token refreshed successfully');
      _isRefreshing = false;
      return true;
    } catch (e) {
      print('[AuthProvider] ❌ Token refresh failed: $e');
      // If refresh fails, user needs to login again
      await _clearTokens();
      _isRefreshing = false;
      return false;
    }
  }

  /// Get valid access token (refresh if needed)
  Future<String?> getValidAccessToken() async {
    if (_accessToken == null) {
      return null;
    }

    if (_shouldRefreshToken()) {
      final refreshed = await refreshAccessToken();
      return refreshed ? _accessToken : null;
    }

    return _accessToken;
  }

  /// Login with username/email and password
  Future<bool> login({
    required String usernameOrEmail,
    required String password,
    bool rememberMe = false,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final request = LoginRequest(
        usernameOrEmail: usernameOrEmail,
        password: password,
        rememberMe: rememberMe,
      );

      final tokenResponse = await _authApiService.login(request);

      // Extract username from usernameOrEmail if it looks like a username
      // Otherwise keep the email
      final username = !usernameOrEmail.contains('@')
          ? usernameOrEmail
          : usernameOrEmail.split('@')[0];

      await _saveTokens(
        tokenResponse.accessToken,
        tokenResponse.refreshToken,
        tokenResponse.expiresIn,
        username,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Register new user
  Future<bool> register({
    required String username,
    required String email,
    required String password,
    String? firstName,
    String? lastName,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final request = RegisterRequest(
        username: username,
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
      );

      await _authApiService.register(request);

      // Store email for OTP verification
      await _prefs.setString('registration_email', email);

      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Verify registration with OTP
  Future<bool> verifyRegistrationOtp({
    required String email,
    required String otp,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final request = VerifyRegistrationRequest(
        email: email.trim().toLowerCase(),
        otp: otp.trim(),
      );

      await _authApiService.verifyRegistration(request);

      // Clear registration email
      await _prefs.remove('registration_email');

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      _errorMessage = errorMsg;
      print('[verifyRegistrationOtp] Error: $errorMsg');
      notifyListeners();
      return false;
    }
  }

  /// Send OTP to email
  Future<bool> sendOtp({required String email}) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final request = SendOtpRequest(email: email);
      await _authApiService.sendOtp(request);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Logout user
  Future<void> logout() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Call logout endpoint
      await _authApiService.logout(_refreshToken);

      // Clear tokens
      await _clearTokens();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
