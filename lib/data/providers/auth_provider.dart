import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kltn_sharing_app/data/models/auth_request_model.dart';
import 'package:kltn_sharing_app/data/services/auth_api_service.dart';
import 'package:kltn_sharing_app/data/services/user_api_service.dart';
import 'package:kltn_sharing_app/data/services/gamification_api_service.dart';

/// Provider for managing authentication state and tokens
class AuthProvider extends ChangeNotifier {
  final AuthApiService _authApiService;
  final UserApiService _userApiService;
  final GamificationApiService _gamificationApiService;
  late SharedPreferences _prefs;

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _usernameKey = 'username';
  static const String _userIdKey = 'user_id';

  String? _accessToken;
  String? _refreshToken;
  String? _username;
  String? _userId;
  bool _isLoading = false;
  String? _errorMessage;
  int _userPoints = 0; // Gamification points

  AuthProvider({
    required AuthApiService authApiService,
    UserApiService? userApiService,
    GamificationApiService? gamificationApiService,
  })  : _authApiService = authApiService,
        _userApiService = userApiService ?? UserApiService(),
        _gamificationApiService =
            gamificationApiService ?? GamificationApiService() {
    _init();
  }

  // Getters
  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  String? get username => _username;
  String? get userId => _userId;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _accessToken != null && _accessToken!.isNotEmpty;
  int get userPoints => _userPoints;

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
    _userId = _prefs.getString(_userIdKey);

    if (_accessToken != null) {
      _authApiService.setAuthToken(_accessToken!);
      _userApiService.setAuthToken(_accessToken!);
      _gamificationApiService.setAuthToken(_accessToken!);

      // Load gamification points when tokens are loaded
      _loadGamificationPoints();
    }

    notifyListeners();
  }

  /// Load gamification points asynchronously
  Future<void> _loadGamificationPoints() async {
    try {
      print('[AuthProvider] 🎮 Loading gamification points...');
      final gamificationStats =
          await _gamificationApiService.getCurrentUserStats();
      _userPoints = gamificationStats.points ?? 0;
      print('[AuthProvider] ✅ Gamification points loaded: $_userPoints');
      notifyListeners();
    } catch (e) {
      print('[AuthProvider] ⚠️  Failed to load gamification points: $e');
      _userPoints = 0;
      // Don't fail - leaderboard still works without points
      notifyListeners();
    }
  }

  /// Public method to reload gamification points
  Future<void> reloadGamificationPoints() async {
    print('[AuthProvider] 🔄 Reloading gamification points...');
    if (_accessToken == null) {
      print('[AuthProvider] ⚠️  No access token available');
      return;
    }
    await _loadGamificationPoints();
  }

  /// Save tokens to shared preferences
  Future<void> _saveTokens(
    String accessToken,
    String refreshToken,
    int expiresInSeconds,
    String? username, {
    String? userId,
  }) async {
    // IMPORTANT: Save refreshToken - required for future token refresh!
    await _prefs.setString(_accessTokenKey, accessToken);
    await _prefs.setString(_refreshTokenKey, refreshToken);
    if (username != null) {
      await _prefs.setString(_usernameKey, username);
    }
    if (userId != null) {
      await _prefs.setString(_userIdKey, userId);
    }

    _accessToken = accessToken;
    _refreshToken = refreshToken;
    _username = username;
    _userId = userId;
    _authApiService.setAuthToken(accessToken);
    _userApiService.setAuthToken(accessToken);

    print('[AuthProvider] ✅ Tokens saved to SharedPreferences');
    print('[AuthProvider] - Access Token: ${accessToken.substring(0, 20)}...');
    print(
        '[AuthProvider] - Refresh Token: ${refreshToken.substring(0, 20)}...');
    print('[AuthProvider] - Username: $username');
    print('[AuthProvider] - User ID: $userId');

    notifyListeners();
  }

  /// Clear all tokens
  Future<void> _clearTokens() async {
    await _prefs.remove(_accessTokenKey);
    await _prefs.remove(_refreshTokenKey);
    await _prefs.remove(_usernameKey);

    _accessToken = null;
    _refreshToken = null;
    _username = null;
    _userPoints = 0;
    _authApiService.removeAuthToken();
    _userApiService.removeAuthToken();
    _gamificationApiService.removeAuthToken();

    notifyListeners();
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

      // Load user data from API /api/v2/users/me after successful login
      try {
        final currentUser = await _userApiService.getCurrentUser();
        print('[AuthProvider] ✅ User data loaded: ${currentUser.fullName}');
        print('[AuthProvider] - Address: ${currentUser.address}');
        print('[AuthProvider] - Phone: ${currentUser.phoneNumber}');

        // Save user ID
        _userId = currentUser.id;
        await _prefs.setString(_userIdKey, currentUser.id);
      } catch (e) {
        print('[AuthProvider] ⚠️  Failed to load user data: $e');
        // Don't fail login if user data load fails
      }

      // Load gamification points
      try {
        _gamificationApiService.setAuthToken(tokenResponse.accessToken);
        final gamificationStats =
            await _gamificationApiService.getCurrentUserStats();
        _userPoints = gamificationStats.points ?? 0;
        print('[AuthProvider] ✅ Gamification points loaded: $_userPoints');
      } catch (e) {
        print('[AuthProvider] ⚠️  Failed to load gamification points: $e');
        _userPoints = 0;
        // Don't fail login if gamification load fails
      }

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

  /// Login with Google
  Future<bool> googleLogin({
    String? idToken,
    String? code,
    String? redirectUri,
    String? codeVerifier,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final tokenResponse = await _authApiService.googleLogin(
        idToken: idToken,
        code: code,
        redirectUri: redirectUri,
        codeVerifier: codeVerifier,
      );

      await _saveTokens(
        tokenResponse.accessToken,
        tokenResponse.refreshToken,
        tokenResponse.expiresIn,
        'google_user', // Default username for Google login
      );

      // Load user data from API
      try {
        final currentUser = await _userApiService.getCurrentUser();
        print(
            '[AuthProvider] ✅ Google login successful: ${currentUser.fullName}');

        // Save user ID
        _userId = currentUser.id;
        await _prefs.setString(_userIdKey, currentUser.id);
      } catch (e) {
        print('[AuthProvider] ⚠️  Failed to load user data: $e');
        // Don't fail login if user data load fails
      }

      // Load gamification points
      try {
        _gamificationApiService.setAuthToken(tokenResponse.accessToken);
        final gamificationStats =
            await _gamificationApiService.getCurrentUserStats();
        _userPoints = gamificationStats.points ?? 0;
        print('[AuthProvider] ✅ Gamification points loaded: $_userPoints');
      } catch (e) {
        print('[AuthProvider] ⚠️  Failed to load gamification points: $e');
        _userPoints = 0;
        // Don't fail login if gamification load fails
      }

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

      // Delete FCM token from backend
      try {
        print('[AuthProvider] 🗑️  Deleting FCM token from backend');
        await _userApiService.deleteFCMToken();
      } catch (e) {
        print('[AuthProvider] ⚠️  Failed to delete FCM token: $e');
        // Continue with logout even if FCM token delete fails
      }

      // Call logout endpoint
      await _authApiService.logout(_refreshToken);

      // Clear cached data (messages, etc.)
      try {
        final prefs = await SharedPreferences.getInstance();
        // Clear message cache
        await prefs.remove('conversations_cache');
        print('[AuthProvider] ✅ Cleared cached conversations');
      } catch (e) {
        print('[AuthProvider] ⚠️  Failed to clear cache: $e');
      }

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

  /// Check if token is valid by attempting to refresh it
  Future<bool> validateAndRefreshToken() async {
    try {
      if (_refreshToken == null || _refreshToken!.isEmpty) {
        print('[AuthProvider] ⚠️  No refresh token found');
        await _clearTokens();
        return false;
      }

      print('[AuthProvider] 🔄 Validating token...');

      // Try to refresh the token
      try {
        final request = RefreshTokenRequest(refreshToken: _refreshToken!);
        final tokenResponse = await _authApiService.refreshToken(request);

        await _saveTokens(
          tokenResponse.accessToken,
          tokenResponse.refreshToken,
          tokenResponse.expiresIn,
          _username,
          userId: _userId,
        );

        print('[AuthProvider] ✅ Token refreshed successfully');
        return true;
      } catch (e) {
        print('[AuthProvider] ⚠️  Token refresh failed: $e');
        // If refresh fails, clear tokens
        await _clearTokens();
        return false;
      }
    } catch (e) {
      print('[AuthProvider] ❌ Error validating token: $e');
      return false;
    }
  }

  /// Restore session on app startup
  Future<void> restoreSession() async {
    try {
      _isLoading = true;
      notifyListeners();

      _loadTokens();

      if (!isLoggedIn) {
        print('[AuthProvider] ℹ️  No saved token found');
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Try to validate and refresh token
      final isValid = await validateAndRefreshToken();
      if (isValid) {
        // Load user data
        try {
          final currentUser = await _userApiService.getCurrentUser();
          print('[AuthProvider] ✅ Session restored: ${currentUser.fullName}');
          _userId = currentUser.id;
          await _prefs.setString(_userIdKey, currentUser.id);
        } catch (e) {
          print('[AuthProvider] ⚠️  Failed to load user data: $e');
          // Token is valid but can't load user data, that's okay
        }
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('[AuthProvider] ❌ Error restoring session: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
