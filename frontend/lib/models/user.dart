class User {
  final int id;
  final String username;
  final String email;
  final String fullName;
  final String role; // 'worker' or 'contractor'
  final String? phone;
  final double trustScore;
  final DateTime createdAt;
  final String? profilePhotoUrl;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.fullName,
    required this.role,
    this.phone,
    required this.trustScore,
    required this.createdAt,
    this.profilePhotoUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final dynamic createdAtRaw = json['created_at'];
    DateTime createdAtValue;

    if (createdAtRaw is String && createdAtRaw.isNotEmpty) {
      createdAtValue = DateTime.parse(createdAtRaw);
    } else {
      createdAtValue = DateTime.now();
    }

    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      fullName: json['full_name'],
      role: json['role'],
      phone: json['phone'],
      trustScore: (json['trust_score'] ?? 50.0).toDouble(),
      createdAt: createdAtValue,
      profilePhotoUrl: json['profile_photo_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'full_name': fullName,
      'role': role,
      'phone': phone,
      'trust_score': trustScore,
      'created_at': createdAt.toIso8601String(),
      'profile_photo_url': profilePhotoUrl,
    };
  }

  bool get isWorker => role == 'worker';
  bool get isContractor => role == 'contractor';
}
