import 'package:spot_for_fun/data/models/notification_dto.dart';
import 'package:spot_for_fun/domain/models/notification.dart';

extension NotificationDtoMapper on NotificationDto {
  AppNotification toDomain() => AppNotification(
        id: id,
        userId: userId,
        kind: kind,
        payload: payload,
        readAt: readAt,
        createdAt: createdAt,
      );
}
