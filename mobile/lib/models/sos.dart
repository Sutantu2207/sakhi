class SOSEvent {
  final String id;
  final String userId;
  final String status;
  final double latitude;
  final double longitude;
  final String? addressApprox;
  final DateTime triggeredAt;
  final DateTime? resolvedAt;
  final int contactsNotifiedCount;
  final String notificationStatus;
  final String? adminNotes;

  SOSEvent({
    required this.id,
    required this.userId,
    required this.status,
    required this.latitude,
    required this.longitude,
    this.addressApprox,
    required this.triggeredAt,
    this.resolvedAt,
    required this.contactsNotifiedCount,
    required this.notificationStatus,
    this.adminNotes,
  });

  factory SOSEvent.fromJson(Map<String, dynamic> json) {
    return SOSEvent(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      status: json['status'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      addressApprox: json['address_approx'] as String?,
      triggeredAt: DateTime.parse(json['triggered_at'] as String),
      resolvedAt: json['resolved_at'] != null ? DateTime.parse(json['resolved_at'] as String) : null,
      contactsNotifiedCount: json['contacts_notified_count'] as int? ?? 0,
      notificationStatus: json['notification_status'] as String? ?? 'SENT',
      adminNotes: json['admin_notes'] as String?,
    );
  }
}
