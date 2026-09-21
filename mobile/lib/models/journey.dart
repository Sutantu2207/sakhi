class Journey {
  final String id;
  final String userId;
  final String status;
  final String? destinationName;
  final double startLat;
  final double startLon;
  final double? currentLat;
  final double? currentLon;
  final double? destinationLat;
  final double? destinationLon;
  final DateTime startTime;
  final DateTime? endTime;
  final double totalDistanceKm;
  final String maxReportedRisk;

  Journey({
    required this.id,
    required this.userId,
    required this.status,
    this.destinationName,
    required this.startLat,
    required this.startLon,
    this.currentLat,
    this.currentLon,
    this.destinationLat,
    this.destinationLon,
    required this.startTime,
    this.endTime,
    required this.totalDistanceKm,
    required this.maxReportedRisk,
  });

  factory Journey.fromJson(Map<String, dynamic> json) {
    return Journey(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      status: json['status'] as String,
      destinationName: json['destination_name'] as String?,
      startLat: (json['start_lat'] as num).toDouble(),
      startLon: (json['start_lon'] as num).toDouble(),
      currentLat: (json['current_lat'] as num?)?.toDouble(),
      currentLon: (json['current_lon'] as num?)?.toDouble(),
      destinationLat: (json['destination_lat'] as num?)?.toDouble(),
      destinationLon: (json['destination_lon'] as num?)?.toDouble(),
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: json['end_time'] != null ? DateTime.parse(json['end_time'] as String) : null,
      totalDistanceKm: (json['total_distance_km'] as num?)?.toDouble() ?? 0.0,
      maxReportedRisk: json['max_reported_risk_encountered'] as String? ?? 'lower_reported_risk',
    );
  }
}

class JourneyShareInfo {
  final String id;
  final String journeyId;
  final String shareToken;
  final DateTime expiresAt;
  final bool isRevoked;
  final int viewsCount;
  final String? shareUrl;

  JourneyShareInfo({
    required this.id,
    required this.journeyId,
    required this.shareToken,
    required this.expiresAt,
    required this.isRevoked,
    required this.viewsCount,
    this.shareUrl,
  });

  factory JourneyShareInfo.fromJson(Map<String, dynamic> json) {
    return JourneyShareInfo(
      id: json['id'] as String,
      journeyId: json['journey_id'] as String,
      shareToken: json['share_token'] as String,
      expiresAt: DateTime.parse(json['expires_at'] as String),
      isRevoked: json['is_revoked'] as bool? ?? false,
      viewsCount: json['views_count'] as int? ?? 0,
      shareUrl: json['share_url'] as String?,
    );
  }
}
