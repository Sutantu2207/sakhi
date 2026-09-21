class User {
  final String id;
  final String email;
  final String? phone;
  final String fullName;
  final String role;
  final bool isActive;
  final bool safetyNetworkOptIn;
  final int locationRetentionDays;
  final DateTime createdAt;

  User({
    required this.id,
    required this.email,
    this.phone,
    required this.fullName,
    required this.role,
    required this.isActive,
    required this.safetyNetworkOptIn,
    required this.locationRetentionDays,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      fullName: json['full_name'] as String,
      role: json['role'] as String,
      isActive: json['is_active'] as bool? ?? true,
      safetyNetworkOptIn: json['safety_network_opt_in'] as bool? ?? false,
      locationRetentionDays: json['location_retention_days'] as int? ?? 7,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'phone': phone,
      'full_name': fullName,
      'role': role,
      'is_active': isActive,
      'safety_network_opt_in': safetyNetworkOptIn,
      'location_retention_days': locationRetentionDays,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
