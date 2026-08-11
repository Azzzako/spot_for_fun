import 'package:spot_for_fun/data/models/profile_dto.dart';
import 'package:spot_for_fun/domain/models/profile.dart';

extension ProfileDtoMapper on ProfileDto {
  Profile toDomain() {
    return Profile(
      id: id,
      username: username,
      avatarUrl: avatarUrl,
      role: role,
      fcmToken: fcmToken,
      createdAt: createdAt,
    );
  }
}
