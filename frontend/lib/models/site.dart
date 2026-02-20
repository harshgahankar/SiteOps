class Site {
  final int id;
  final String name;
  final String locationAddress;
  final double latitude;
  final double longitude;
  final double geofenceRadius;
  final String supervisorName;
  final String shiftStartTime;
  final String projectPhase;
  final DateTime? projectDeadline;
  final double progressPercentage;
  final int contractorId;

  Site({
    required this.id,
    required this.name,
    required this.locationAddress,
    required this.latitude,
    required this.longitude,
    required this.geofenceRadius,
    required this.supervisorName,
    required this.shiftStartTime,
    required this.projectPhase,
    this.projectDeadline,
    required this.progressPercentage,
    required this.contractorId,
  });

  factory Site.fromJson(Map<String, dynamic> json) {
    return Site(
      id: json['id'],
      name: json['name'],
      locationAddress: json['location_address'],
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
      geofenceRadius: json['geofence_radius'].toDouble(),
      supervisorName: json['supervisor_name'],
      shiftStartTime: json['shift_start_time'],
      projectPhase: json['project_phase'],
      projectDeadline: json['project_deadline'] != null
          ? DateTime.parse(json['project_deadline'])
          : null,
      progressPercentage: (json['progress_percentage'] ?? 0.0).toDouble(),
      contractorId: json['contractor_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'location_address': locationAddress,
      'latitude': latitude,
      'longitude': longitude,
      'geofence_radius': geofenceRadius,
      'supervisor_name': supervisorName,
      'shift_start_time': shiftStartTime,
      'project_phase': projectPhase,
      'project_deadline': projectDeadline?.toIso8601String(),
      'progress_percentage': progressPercentage,
      'contractor_id': contractorId,
    };
  }
}
