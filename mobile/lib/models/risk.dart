class AreaRisk {
  final double latitude;
  final double longitude;
  final double riskScore;
  final String riskCategory;
  final double confidence;
  final String summary;
  final List<String> contributingFactors;
  final int nearbyIncidentsCount;
  final double? nearestPoliceKm;
  final double? nearestHospitalKm;
  final String modelVersion;

  AreaRisk({
    required this.latitude,
    required this.longitude,
    required this.riskScore,
    required this.riskCategory,
    required this.confidence,
    required this.summary,
    required this.contributingFactors,
    required this.nearbyIncidentsCount,
    this.nearestPoliceKm,
    this.nearestHospitalKm,
    required this.modelVersion,
  });

  factory AreaRisk.fromJson(Map<String, dynamic> json) {
    return AreaRisk(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      riskScore: (json['risk_score'] as num).toDouble(),
      riskCategory: json['risk_category'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      summary: json['summary'] as String,
      contributingFactors: (json['contributing_factors'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      nearbyIncidentsCount: json['nearby_incidents_count'] as int? ?? 0,
      nearestPoliceKm: (json['nearest_police_km'] as num?)?.toDouble(),
      nearestHospitalKm: (json['nearest_hospital_km'] as num?)?.toDouble(),
      modelVersion: json['model_version'] as String? ?? 'sakhi-risk-xgb-v1.0',
    );
  }
}
