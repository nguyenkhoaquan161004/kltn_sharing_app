import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Location Service - Manages user location globally
/// Provides methods to get current location, save, and retrieve stored location
class LocationService {
  static final LocationService _instance = LocationService._internal();

  double? _latitude;
  double? _longitude;

  factory LocationService() {
    return _instance;
  }

  LocationService._internal();

  // Getters
  double? get latitude => _latitude;
  double? get longitude => _longitude;
  bool get hasLocation => _latitude != null && _longitude != null;

  /// Initialize location service with stored location if available
  Future<void> initialize() async {
    await _loadStoredLocation();
  }

  /// Load location from local storage
  Future<void> _loadStoredLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _latitude = prefs.getDouble('user_latitude');
      _longitude = prefs.getDouble('user_longitude');
      print(
          '[LocationService] Loaded stored location: $_latitude, $_longitude');
    } catch (e) {
      print('[LocationService] Error loading stored location: $e');
    }
  }

  /// Get current location
  Future<Position?> getCurrentLocation() async {
    try {
      final isLocationServiceEnabled =
          await Geolocator.isLocationServiceEnabled();
      if (!isLocationServiceEnabled) {
        print('[LocationService] Location service is disabled');
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _latitude = position.latitude;
      _longitude = position.longitude;

      // Save to shared preferences
      await _saveLocation();
      print('[LocationService] Updated location: $_latitude, $_longitude');

      return position;
    } catch (e) {
      print('[LocationService] Error getting current location: $e');
      return null;
    }
  }

  /// Save current location to shared preferences
  Future<void> _saveLocation() async {
    try {
      if (_latitude != null && _longitude != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setDouble('user_latitude', _latitude!);
        await prefs.setDouble('user_longitude', _longitude!);
        print('[LocationService] Location saved to preferences');
      }
    } catch (e) {
      print('[LocationService] Error saving location: $e');
    }
  }

  /// Update location manually with new coordinates
  Future<void> updateLocation(double latitude, double longitude) async {
    _latitude = latitude;
    _longitude = longitude;
    await _saveLocation();
    print('[LocationService] Location updated: $_latitude, $_longitude');
  }
}
