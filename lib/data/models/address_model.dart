class Province {
  final String id;
  final String name;
  final List<District> districts;

  Province({
    required this.id,
    required this.name,
    required this.districts,
  });
}

class District {
  final String id;
  final String name;
  final String provinceId;
  final List<Ward> wards;

  District({
    required this.id,
    required this.name,
    required this.provinceId,
    required this.wards,
  });
}

class Ward {
  final String id;
  final String name;
  final String districtId;

  Ward({
    required this.id,
    required this.name,
    required this.districtId,
  });
}

class UserAddress {
  final String streetAddress; // Số nhà + Tên đường
  final String wardId;
  final String wardName;
  final String districtId;
  final String districtName;
  final String provinceId;
  final String provinceName;
  final double? latitude;
  final double? longitude;

  UserAddress({
    required this.streetAddress,
    required this.wardId,
    required this.wardName,
    required this.districtId,
    required this.districtName,
    required this.provinceId,
    required this.provinceName,
    this.latitude,
    this.longitude,
  });

  /// Get full address string for display
  String getFullAddress() {
    return '$streetAddress, $wardName, $districtName, $provinceName';
  }

  /// Convert to JSON for API
  Map<String, dynamic> toJson() {
    return {
      'streetAddress': streetAddress,
      'ward': wardName,
      'district': districtName,
      'province': provinceName,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  @override
  String toString() => getFullAddress();
}
