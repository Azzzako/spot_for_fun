import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:spot_for_fun/data/models/notification_dto.dart';
import 'package:spot_for_fun/ui/core/providers/supabase_client_provider.dart';

class NotificationsService {
  NotificationsService(this._client);
  final SupabaseClient _client;

  Future<List<NotificationDto>> fetchAll() async {
    final res = await _client
        .from('notifications')
        .select()
        .order('created_at', ascending: false)
        .limit(50);
    return (res as List)
        .cast<Map<String, dynamic>>()
        .map(NotificationDto.fromMap)
        .toList(growable: false);
  }

  Future<void> markRead(String id) async {
    await _client
        .from('notifications')
        .update({'read_at': DateTime.now().toIso8601String()})
        .eq('id', id);
  }

  Future<void> markAllRead() async {
    await _client
        .from('notifications')
        .update({'read_at': DateTime.now().toIso8601String()})
        .isFilter('read_at', null);
  }

  /// Stream of new rows as they arrive via Supabase Realtime. The
  /// caller filters by user_id client-side; RLS only lets the user
  /// see their own rows anyway.
  Stream<List<NotificationDto>> watchNew(String userId) {
    return _client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(20)
        .map((rows) => rows
            .cast<Map<String, dynamic>>()
            .map(NotificationDto.fromMap)
            .toList(growable: false));
  }
}

final notificationsServiceProvider =
    Provider<NotificationsService>((ref) {
  return NotificationsService(ref.watch(supabaseClientProvider));
});
