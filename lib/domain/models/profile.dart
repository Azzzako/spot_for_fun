import 'package:spot_for_fun/domain/user_role.dart';

class Profile {
  const Profile({
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

  Profile copyWith({
    String? username,
    String? avatarUrl,
    String? fcmToken,
  }) {
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
