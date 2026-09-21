class EmergencyContact {
  final String id;
  final String userId;
  final String name;
  final String phone;
  final String? relationshipLabel;
  final bool notifyOnSos;
  final int priorityOrder;
  final DateTime createdAt;

  EmergencyContact({
    required this.id,
    required this.userId,
    required this.name,
    required this.phone,
    this.relationshipLabel,
    required this.notifyOnSos,
    required this.priorityOrder,
    required this.createdAt,
  });

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      relationshipLabel: json['relationship_label'] as String?,
      notifyOnSos: json['notify_on_sos'] as bool? ?? true,
      priorityOrder: json['priority_order'] as int? ?? 1,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
