class EmergencyResource {
  final String id;
  final String name;
  final String category;
  final String phone;
  final String address;
  final double latitude;
  final double longitude;
  final bool isVerified;
  final String operatingHours;
  final double? distanceKm;

  EmergencyResource({
    required this.id,
    required this.name,
    required this.category,
    required this.phone,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.isVerified,
    required this.operatingHours,
    this.distanceKm,
  });

  factory EmergencyResource.fromJson(Map<String, dynamic> json) {
    return EmergencyResource(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      phone: json['phone'] as String,
      address: json['address'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      isVerified: json['is_verified'] as bool? ?? true,
      operatingHours: json['operating_hours'] as String? ?? '24/7',
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
    );
  }
}

class SupportResource {
  final String id;
  final String category;
  final String title;
  final String organization;
  final String? phone;
  final String? website;
  final String description;
  final String jurisdiction;
  final String? actionableSteps;

  SupportResource({
    required this.id,
    required this.category,
    required this.title,
    required this.organization,
    this.phone,
    this.website,
    required this.description,
    required this.jurisdiction,
    this.actionableSteps,
  });

  factory SupportResource.fromJson(Map<String, dynamic> json) {
    return SupportResource(
      id: json['id'] as String,
      category: json['category'] as String,
      title: json['title'] as String,
      organization: json['organization'] as String,
      phone: json['phone'] as String?,
      website: json['website'] as String?,
      description: json['description'] as String,
      jurisdiction: json['jurisdiction'] as String? ?? 'National',
      actionableSteps: json['actionable_steps'] as String?,
    );
  }
}
