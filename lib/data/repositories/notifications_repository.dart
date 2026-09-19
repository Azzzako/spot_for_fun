import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:spot_for_fun/data/repositories/auth_provider.dart';
import 'package:spot_for_fun/data/services/notifications_service.dart';
import 'package:spot_for_fun/domain/mappers/notification_mapper.dart';
import 'package:spot_for_fun/domain/models/notification.dart';

class NotificationsRepository {
  NotificationsRepository(this._service);
  final NotificationsService _service;

  Future<List<AppNotification>> list() async {
    final dtos = await _service.fetchAll();
    return dtos.map((d) => d.toDomain()).toList(growable: false);
  }

  Future<void> markRead(String id) => _service.markRead(id);

  Future<void> markAllRead() => _service.markAllRead();

  Stream<List<AppNotification>> watch(String userId) {
    return _service.watchNew(userId).map(
          (dtos) => dtos.map((d) => d.toDomain()).toList(growable: false),
        );
  }
}

final notificationsRepositoryProvider =
    Provider<NotificationsRepository>((ref) {
  return NotificationsRepository(ref.watch(notificationsServiceProvider));
});

/// Initial fetch + Realtime subscription. Emits the latest 50
/// notifications for the signed-in user (empty list when anonymous).
final notificationsFeedProvider =
    StreamProvider.autoDispose<List<AppNotification>>((ref) async* {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) {
    yield const <AppNotification>[];
    return;
  }
  final repo = ref.watch(notificationsRepositoryProvider);
  final initial = await repo.list();
  yield initial;
  yield* repo.watch(uid);
});
