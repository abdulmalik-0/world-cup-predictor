class Profile {
  const Profile({
    required this.id,
    required this.fullName,
    required this.department,
    this.avatarUrl,
    this.isAdmin = false,
    required this.createdAt,
  });

  final String id;
  final String fullName;
  final String department;
  final String? avatarUrl;
  final bool isAdmin;
  final DateTime createdAt;

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      fullName: json['full_name'] as String,
      department: json['department'] as String,
      avatarUrl: json['avatar_url'] as String?,
      isAdmin: json['is_admin'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'full_name': fullName,
        'department': department,
        'avatar_url': avatarUrl,
      };
}
