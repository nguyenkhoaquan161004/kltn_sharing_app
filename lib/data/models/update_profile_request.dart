class UpdateProfileRequest {
  final String? userId;
  final String? firstName;
  final String? lastName;
  final String? avatarUrl;
  final DateTime? birthDate;
  final String? address;
  final String? phone;
  final double? latitude;
  final double? longitude;

  UpdateProfileRequest({
    this.userId,
    this.firstName,
    this.lastName,
    this.avatarUrl,
    this.birthDate,
    this.address,
    this.phone,
    this.latitude,
    this.longitude,
  });

  Map<String, dynamic> toJson() {
    return {
      if (userId != null) 'userId': userId,
      if (firstName != null) 'firstName': firstName,
      if (lastName != null) 'lastName': lastName,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      if (birthDate != null)
        'birthDate':
            birthDate?.toIso8601String().split('T').first, // YYYY-MM-DD format
      if (address != null) 'address': address,
      if (phone != null) 'phone': phone,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    };
  }
}
