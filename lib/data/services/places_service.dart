import 'package:geocoding/geocoding.dart' as geo;
import 'package:kltn_sharing_app/data/models/location_model.dart';

/// Service for handling place/location searches
class PlacesService {
  /// Search for locations/places by name
  /// Returns a list of LocationModel with matching places
  static Future<List<LocationModel>> searchPlaces(String query) async {
    if (query.isEmpty) {
      return [];
    }

    try {
      print('[PlacesService] Searching for places: "$query"');

      // Use the geocoding package to get location from address name
      final locations = await geo.locationFromAddress(query);

      if (locations.isEmpty) {
        print('[PlacesService] No locations found for query: "$query"');
        return [];
      }

      // Convert to LocationModel
      final results = locations.map((location) {
        return LocationModel(
          locationId: 0, // Placeholder ID for search results
          name: query,
          latitude: location.latitude,
          longitude: location.longitude,
        );
      }).toList();

      print('[PlacesService] Found ${results.length} location(s)');
      return results;
    } catch (e) {
      print('[PlacesService] Error searching places: $e');
      return [];
    }
  }

  /// Get address name from coordinates (reverse geocoding)
  static Future<String?> getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      print(
          '[PlacesService] Getting address from coordinates: $latitude, $longitude');

      final placemarks =
          await geo.placemarkFromCoordinates(latitude, longitude);

      if (placemarks.isEmpty) {
        print('[PlacesService] No address found for coordinates');
        return null;
      }

      final placemark = placemarks.first;

      // Build address string from components
      final addressParts = [
        placemark.name,
        placemark.street,
        placemark.locality,
        placemark.administrativeArea,
      ].where((part) => part != null && part.isNotEmpty).toList();

      final address = addressParts.join(', ');
      print('[PlacesService] Found address: $address');

      return address;
    } catch (e) {
      print('[PlacesService] Error getting address: $e');
      return null;
    }
  }
}
