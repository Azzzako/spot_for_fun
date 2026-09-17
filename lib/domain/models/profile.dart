import 'package:spot_for_fun/domain/enums.dart';
import 'package:spot_for_fun/domain/user_role.dart';

class Profile {
  const Profile({
    required this.id,
    required this.username,
    this.aka,
    this.instagram,
    this.avatarUrl,
    required this.role,
    this.fcmToken,
    required this.createdAt,
    this.displayAs = DisplayAs.username,
  });

  final String id;
  final String username;
  final String? aka;
  final String? instagram;
  final String? avatarUrl;
  final UserRole role;
  final String? fcmToken;
  final DateTime createdAt;
  final DisplayAs displayAs;

  bool get isAdmin => role == UserRole.admin;

  String get displayName {
    final akaValue = aka?.trim();
    if (displayAs == DisplayAs.aka && akaValue != null && akaValue.isNotEmpty) {
      return akaValue;
    }
    return username;
  }

  Profile copyWith({
    String? username,
    String? aka,
    String? instagram,
    String? avatarUrl,
    String? fcmToken,
    DisplayAs? displayAs,
  }) {
    return Profile(
      id: id,
      username: username ?? this.username,
      aka: aka ?? this.aka,
      instagram: instagram ?? this.instagram,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt,
      displayAs: displayAs ?? this.displayAs,
    );
  }
}
