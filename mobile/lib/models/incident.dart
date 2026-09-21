class Incident {
  final String id;
  final String? reporterId;
  final bool isAnonymous;
  final String category;
  final String severity;
  final String description;
  final DateTime incidentTime;
  final double latitude;
  final double longitude;
  final String status;
  final String? moderatorNotes;

  Incident({
    required this.id,
    this.reporterId,
    required this.isAnonymous,
    required this.category,
    required this.severity,
    required this.description,
    required this.incidentTime,
    required this.latitude,
    required this.longitude,
    required this.status,
    this.moderatorNotes,
  });

  factory Incident.fromJson(Map<String, dynamic> json) {
    return Incident(
      id: json['id'] as String,
      reporterId: json['reporter_id'] as String?,
      isAnonymous: json['is_anonymous'] as bool? ?? false,
      category: json['category'] as String,
      severity: json['severity'] as String,
      description: json['description'] as String,
      incidentTime: DateTime.parse(json['incident_time'] as String),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      status: json['status'] as String,
      moderatorNotes: json['moderator_notes'] as String?,
    );
  }
}
