import 'user_role.dart';

class Profile {
  Profile({
    required this.id,
    required this.username,
    this.avatarUrl,
    required this.role,
    this.fcmToken,
    required this.createdAt,
  });

  final String id;
  final String username;
  final String? avatarUrl;
  final UserRole role;
  final String? fcmToken;
  final DateTime createdAt;

  bool get isAdmin => role == UserRole.admin;

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['id'] as String,
      username: (map['username'] as String?) ?? '',
      avatarUrl: map['avatar_url'] as String?,
      role: UserRoleX.fromDb(map['role']),
      fcmToken: map['fcm_token'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'username': username,
        'avatar_url': avatarUrl,
        'role': role.dbValue,
        'fcm_token': fcmToken,
      };

  Profile copyWith({String? username, String? avatarUrl, String? fcmToken}) {
    return Profile(
      id: id,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt,
    );
  }
}
