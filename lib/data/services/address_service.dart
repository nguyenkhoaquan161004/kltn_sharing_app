import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/address_model.dart';

class AddressService {
  static const String _nominatimUrl = 'https://nominatim.openstreetmap.org';

  /// Search addresses using Nominatim API (OpenStreetMap)
  /// Returns list of address suggestions with lat/long
  static Future<List<AddressSuggestion>> searchAddressesByText(
    String query,
  ) async {
    if (query.isEmpty) return [];

    try {
      print('[AddressService] Searching addresses: $query');

      final response = await http.get(
        Uri.parse(
          '$_nominatimUrl/search?q=$query&format=json&addressdetails=1&limit=10&accept-language=vi',
        ),
        headers: {
          'User-Agent': 'kltn-sharing-app/1.0',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> results = jsonDecode(response.body);
        print('[AddressService] Found ${results.length} results');

        return results.map((result) {
          return AddressSuggestion(
            addressName: result['display_name'] ?? '',
            latitude: double.parse(result['lat'] ?? '0'),
            longitude: double.parse(result['lon'] ?? '0'),
            fullData: result,
          );
        }).toList();
      }

      print('[AddressService] API error: ${response.statusCode}');
      return [];
    } catch (e) {
      print('[AddressService] Error searching addresses: $e');
      return [];
    }
  }

  /// Get address details from coordinates (Reverse geocoding)
  static Future<UserAddress?> reverseGeocodeCoordinates({
    required double latitude,
    required double longitude,
  }) async {
    try {
      print('[AddressService] Reverse geocoding: $latitude, $longitude');

      final response = await http.get(
        Uri.parse(
          '$_nominatimUrl/reverse?format=json&lat=$latitude&lon=$longitude&zoom=18&addressdetails=1&accept-language=vi',
        ),
        headers: {
          'User-Agent': 'kltn-sharing-app/1.0',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        final address = result['address'] ?? {};

        return UserAddress(
          streetAddress:
              '${address['house_number'] ?? ''} ${address['road'] ?? ''}'
                  .trim(),
          wardId: '',
          wardName: address['suburb'] ?? address['village'] ?? '',
          districtId: '',
          districtName: address['city_district'] ?? address['county'] ?? '',
          provinceId: '',
          provinceName: address['state'] ?? '',
          latitude: latitude,
          longitude: longitude,
        );
      }

      return null;
    } catch (e) {
      print('[AddressService] Error reverse geocoding: $e');
      return null;
    }
  }

  /// Convert address text to coordinates (forward geocoding)
  static Future<UserAddress?> geocodeAddressText(String address) async {
    try {
      print('[AddressService] Geocoding address: $address');

      final response = await http.get(
        Uri.parse(
          '$_nominatimUrl/search?q=$address&format=json&addressdetails=1&limit=1&accept-language=vi',
        ),
        headers: {
          'User-Agent': 'kltn-sharing-app/1.0',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> results = jsonDecode(response.body);
        if (results.isNotEmpty) {
          final result = results.first;
          final addressData = result['address'] ?? {};

          return UserAddress(
            streetAddress:
                '${addressData['house_number'] ?? ''} ${addressData['road'] ?? ''}'
                    .trim(),
            wardId: '',
            wardName: addressData['suburb'] ?? addressData['village'] ?? '',
            districtId: '',
            districtName:
                addressData['city_district'] ?? addressData['county'] ?? '',
            provinceId: '',
            provinceName: addressData['state'] ?? '',
            latitude: double.parse(result['lat'] ?? '0'),
            longitude: double.parse(result['lon'] ?? '0'),
          );
        }
      }

      return null;
    } catch (e) {
      print('[AddressService] Error geocoding address: $e');
      return null;
    }
  }
}

/// Address suggestion from Nominatim
class AddressSuggestion {
  final String addressName;
  final double latitude;
  final double longitude;
  final Map<String, dynamic> fullData;

  AddressSuggestion({
    required this.addressName,
    required this.latitude,
    required this.longitude,
    required this.fullData,
  });

  @override
  String toString() =>
      'AddressSuggestion(address: $addressName, lat: $latitude, lon: $longitude)';
}
