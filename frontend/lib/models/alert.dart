class Alert {
  final int id;
  final int siteId;
  final String alertType; // 'safety_violation', 'material_delay', 'equipment_failure'
  final String title;
  final String description;
  final String severity; // 'low', 'medium', 'high'
  final bool isResolved;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  Alert({
    required this.id,
    required this.siteId,
    required this.alertType,
    required this.title,
    required this.description,
    required this.severity,
    required this.isResolved,
    required this.createdAt,
    this.resolvedAt,
  });

  factory Alert.fromJson(Map<String, dynamic> json) {
    return Alert(
      id: json['id'],
      siteId: json['site_id'],
      alertType: json['alert_type'],
      title: json['title'],
      description: json['description'],
      severity: json['severity'],
      isResolved: json['is_resolved'],
      createdAt: DateTime.parse(json['created_at']),
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'site_id': siteId,
      'alert_type': alertType,
      'title': title,
      'description': description,
      'severity': severity,
      'is_resolved': isResolved,
      'created_at': createdAt.toIso8601String(),
      'resolved_at': resolvedAt?.toIso8601String(),
    };
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
