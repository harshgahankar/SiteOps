class Attendance {
  final int id;
  final int workerId;
  final int siteId;
  final DateTime checkInTime;
  final DateTime? checkOutTime;
  final bool locationVerified;
  final bool deviceVerified;
  final bool biometricVerified;
  final double locationLat;
  final double locationLng;
  final String deviceInfo;
  final String status; // 'checked_in', 'checked_out', 'absent'

  Attendance({
    required this.id,
    required this.workerId,
    required this.siteId,
    required this.checkInTime,
    this.checkOutTime,
    required this.locationVerified,
    required this.deviceVerified,
    required this.biometricVerified,
    required this.locationLat,
    required this.locationLng,
    required this.deviceInfo,
    required this.status,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: json['id'],
      workerId: json['worker_id'],
      siteId: json['site_id'],
      checkInTime: DateTime.parse(json['check_in_time']),
      checkOutTime: json['check_out_time'] != null
          ? DateTime.parse(json['check_out_time'])
          : null,
      locationVerified: json['location_verified'],
      deviceVerified: json['device_verified'],
      biometricVerified: json['biometric_verified'],
      locationLat: json['location_lat'].toDouble(),
      locationLng: json['location_lng'].toDouble(),
      deviceInfo: json['device_info'],
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'worker_id': workerId,
      'site_id': siteId,
      'check_in_time': checkInTime.toIso8601String(),
      'check_out_time': checkOutTime?.toIso8601String(),
      'location_verified': locationVerified,
      'device_verified': deviceVerified,
      'biometric_verified': biometricVerified,
      'location_lat': locationLat,
      'location_lng': locationLng,
      'device_info': deviceInfo,
      'status': status,
    };
  }

  bool get isCheckedIn => status == 'checked_in';
  bool get isCheckedOut => status == 'checked_out';
}
