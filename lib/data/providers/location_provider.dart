import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationProvider extends ChangeNotifier {
  double? _latitude;
  double? _longitude;
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _updateTimer;

  // Getters
  double? get latitude => _latitude;
  double? get longitude => _longitude;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasLocation => _latitude != null && _longitude != null;

  LocationProvider() {
    _loadStoredLocation();
  }

  /// Load location from local storage
  Future<void> _loadStoredLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _latitude = prefs.getDouble('user_latitude');
      _longitude = prefs.getDouble('user_longitude');
      notifyListeners();
    } catch (e) {
      print('[LocationProvider] Error loading stored location: $e');
    }
  }

  /// Request location permission and get initial location
  Future<void> requestLocationPermissionAndGetLocation() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Check if location services are enabled
      final isLocationServiceEnabled =
          await Geolocator.isLocationServiceEnabled();
      if (!isLocationServiceEnabled) {
        _errorMessage = 'Dịch vụ vị trí chưa được bật';
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Request permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _errorMessage = 'Quyền truy cập vị trí bị từ chối';
          _isLoading = false;
          notifyListeners();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _errorMessage =
            'Quyền truy cập vị trí bị từ chối vĩnh viễn. Vui lòng bật trong cài đặt.';
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Get current position
      await _updateLocation();

      // Start periodic update (every 7 minutes)
      _startPeriodicUpdate();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Lỗi: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      print('[LocationProvider] Error: $e');
    }
  }

  /// Update location and save to shared preferences
  Future<void> _updateLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _latitude = position.latitude;
      _longitude = position.longitude;

      // Save to shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('user_latitude', _latitude!);
      await prefs.setDouble('user_longitude', _longitude!);

      print('[LocationProvider] Location updated: $_latitude, $_longitude');
      notifyListeners();
    } catch (e) {
      print('[LocationProvider] Error updating location: $e');
      _errorMessage = 'Không thể lấy vị trí: $e';
      notifyListeners();
    }
  }

  /// Start periodic location update (every 7 minutes)
  void _startPeriodicUpdate() {
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(const Duration(minutes: 7), (_) async {
      await _updateLocation();
    });
    print('[LocationProvider] Periodic location update started (every 7 min)');
  }

  /// Stop periodic update
  void stopPeriodicUpdate() {
    _updateTimer?.cancel();
    _updateTimer = null;
    print('[LocationProvider] Periodic location update stopped');
  }

  /// Manually refresh location
  Future<void> refreshLocation() async {
    await _updateLocation();
  }

  @override
  void dispose() {
    stopPeriodicUpdate();
    super.dispose();
  }
}
