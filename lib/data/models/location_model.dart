class LocationModel {
  final int locationId;
  final String name;
  final double latitude;
  final double longitude;

  LocationModel({
    required this.locationId,
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      locationId: json['location_id'] ?? 0,
      name: json['name'] ?? '',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'location_id': locationId,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  LocationModel copyWith({
    int? locationId,
    String? name,
    double? latitude,
    double? longitude,
  }) {
    return LocationModel(
      locationId: locationId ?? this.locationId,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}
