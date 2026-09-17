import 'package:spot_for_fun/domain/enums.dart';
import 'package:spot_for_fun/domain/user_role.dart';

class ProfileDto {
  ProfileDto({
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

  factory ProfileDto.fromMap(Map<String, dynamic> map) {
    return ProfileDto(
      id: map['id'] as String,
      username: (map['username'] as String?) ?? '',
      aka: map['aka'] as String?,
      instagram: map['instagram'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      role: UserRoleX.fromDb(map['role']),
      fcmToken: map['fcm_token'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      displayAs: DisplayAsX.fromDb(map['display_as']),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'username': username,
        'aka': aka,
        'instagram': instagram,
        'avatar_url': avatarUrl,
        'role': role.dbValue,
        'fcm_token': fcmToken,
        'display_as': displayAs.dbValue,
      };

  ProfileDto copyWith({
    String? username,
    String? aka,
    String? instagram,
    String? avatarUrl,
    String? fcmToken,
    DisplayAs? displayAs,
  }) {
    return ProfileDto(
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
