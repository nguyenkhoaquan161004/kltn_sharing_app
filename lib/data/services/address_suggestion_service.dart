import 'package:geocoding/geocoding.dart';

/// Address Suggestion Service
/// Provides address autocomplete suggestions and geocoding
/// Filtered to Vietnam only (coordinates: 8.5°N to 23.4°N, 102.0°E to 109.5°E)
class AddressSuggestionService {
  static final AddressSuggestionService _instance =
      AddressSuggestionService._internal();

  // Vietnam boundaries
  static const double VN_MIN_LAT = 8.5;
  static const double VN_MAX_LAT = 23.4;
  static const double VN_MIN_LON = 102.0;
  static const double VN_MAX_LON = 109.5;

  factory AddressSuggestionService() {
    return _instance;
  }

  AddressSuggestionService._internal();

  /// Check if coordinates are within Vietnam
  bool _isInVietnam(double latitude, double longitude) {
    return latitude >= VN_MIN_LAT &&
        latitude <= VN_MAX_LAT &&
        longitude >= VN_MIN_LON &&
        longitude <= VN_MAX_LON;
  }

  /// Get location predictions from address string
  /// Returns list of addresses that match the query with full address formatting (Vietnam only)
  Future<List<LocationPrediction>> getAddressPredictions(String query) async {
    try {
      if (query.isEmpty) {
        return [];
      }

      // Get locations from address
      List<Location> locations = await locationFromAddress(query);

      if (locations.isEmpty) {
        print('[AddressSuggestion] No results found for: $query');
        return [];
      }

      // Filter to Vietnam only
      final vietnamLocations = locations.where((loc) {
        final inVietnam = _isInVietnam(loc.latitude, loc.longitude);
        if (!inVietnam) {
          print(
              '[AddressSuggestion] Filtered out non-Vietnam location: Lat=${loc.latitude}, Lon=${loc.longitude}');
        }
        return inVietnam;
      }).toList();

      if (vietnamLocations.isEmpty) {
        print('[AddressSuggestion] No Vietnam results found for: $query');
        return [];
      }

      // Convert to predictions with full address formatting
      final predictions = <LocationPrediction>[];
      for (var loc in vietnamLocations) {
        try {
          // Get full address details using reverse geocoding
          List<Placemark> placemarks =
              await placemarkFromCoordinates(loc.latitude, loc.longitude);

          if (placemarks.isNotEmpty) {
            final place = placemarks.first;
            final displayAddress = _formatAddress(place);

            predictions.add(LocationPrediction(
              address: query,
              displayAddress: displayAddress,
              latitude: loc.latitude,
              longitude: loc.longitude,
            ));
          } else {
            // Fallback if reverse geocoding fails
            predictions.add(LocationPrediction(
              address: query,
              displayAddress: query,
              latitude: loc.latitude,
              longitude: loc.longitude,
            ));
          }
        } catch (e) {
          print('[AddressSuggestion] Error reverse geocoding location: $e');
          // Fallback prediction
          predictions.add(LocationPrediction(
            address: query,
            displayAddress: query,
            latitude: loc.latitude,
            longitude: loc.longitude,
          ));
        }
      }

      print(
          '[AddressSuggestion] Found ${predictions.length} Vietnam predictions');
      return predictions;
    } catch (e) {
      print('[AddressSuggestion] Error getting predictions: $e');
      return [];
    }
  }

  /// Get lat/long from address (Vietnam only)
  Future<LocationPrediction?> getLocationFromAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);

      if (locations.isEmpty) {
        print('[AddressSuggestion] Could not geocode: $address');
        return null;
      }

      // Filter to Vietnam
      final vietnamLocation = locations.firstWhere(
        (loc) => _isInVietnam(loc.latitude, loc.longitude),
        orElse: () => null as dynamic,
      ) as Location?;

      if (vietnamLocation == null) {
        print('[AddressSuggestion] Address not in Vietnam: $address');
        return null;
      }

      // Get full address details
      List<Placemark> placemarks = await placemarkFromCoordinates(
          vietnamLocation.latitude, vietnamLocation.longitude);
      String displayAddress = address;
      if (placemarks.isNotEmpty) {
        displayAddress = _formatAddress(placemarks.first);
      }

      return LocationPrediction(
        address: address,
        displayAddress: displayAddress,
        latitude: vietnamLocation.latitude,
        longitude: vietnamLocation.longitude,
      );
    } catch (e) {
      print('[AddressSuggestion] Error geocoding address: $e');
      return null;
    }
  }

  /// Get address from lat/long (reverse geocoding) - Vietnam only
  Future<String?> getAddressFromLocation(
      double latitude, double longitude) async {
    try {
      // Check if location is in Vietnam
      if (!_isInVietnam(latitude, longitude)) {
        print(
            '[AddressSuggestion] Coordinates not in Vietnam: Lat=$latitude, Lon=$longitude');
        return null;
      }

      List<Placemark> placemarks =
          await placemarkFromCoordinates(latitude, longitude);

      if (placemarks.isEmpty) {
        print('[AddressSuggestion] Could not reverse geocode coordinates');
        return null;
      }

      final place = placemarks.first;
      return _formatAddress(place);
    } catch (e) {
      print('[AddressSuggestion] Error reverse geocoding: $e');
      return null;
    }
  }

  /// Format placemark to readable address
  String _formatAddress(Placemark place) {
    final parts = <String>[];

    if (place.street != null && place.street!.isNotEmpty) {
      parts.add(place.street!);
    }
    if (place.subLocality != null && place.subLocality!.isNotEmpty) {
      parts.add(place.subLocality!);
    }
    if (place.locality != null && place.locality!.isNotEmpty) {
      parts.add(place.locality!);
    }
    if (place.administrativeArea != null &&
        place.administrativeArea!.isNotEmpty) {
      parts.add(place.administrativeArea!);
    }

    return parts.join(', ');
  }
}

/// Location Prediction Model
class LocationPrediction {
  final String address; // Original search query
  final String displayAddress; // Formatted full address with district/city
  final double latitude;
  final double longitude;

  LocationPrediction({
    required this.address,
    required this.displayAddress,
    required this.latitude,
    required this.longitude,
  });

  @override
  String toString() =>
      'LocationPrediction(displayAddress: $displayAddress, lat: $latitude, lon: $longitude)';
}
