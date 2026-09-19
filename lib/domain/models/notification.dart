import 'package:flutter/foundation.dart';

import 'package:spot_for_fun/domain/enums.dart';

@immutable
class AppNotification {
  const AppNotification({
    required this.id,
    required this.userId,
    required this.kind,
    required this.payload,
    this.readAt,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final NotificationKind kind;
  final Map<String, dynamic> payload;
  final DateTime? readAt;
  final DateTime createdAt;

  bool get isRead => readAt != null;
}
