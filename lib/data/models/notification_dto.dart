import 'package:spot_for_fun/domain/enums.dart';

class NotificationDto {
  NotificationDto({
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

  factory NotificationDto.fromMap(Map<String, dynamic> map) {
    return NotificationDto(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      kind: NotificationKindX.fromDb(map['kind']),
      payload: (map['payload'] as Map?)?.cast<String, dynamic>() ?? const {},
      readAt: map['read_at'] == null
          ? null
          : DateTime.parse(map['read_at'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
