import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:spot_for_fun/data/models/spot_photo_dto.dart';
import 'package:spot_for_fun/data/models/spot_rating_dto.dart';
import 'package:spot_for_fun/domain/enums.dart';
import 'package:spot_for_fun/ui/core/providers/supabase_client_provider.dart';

const _authorSelect =
    'author:profiles!spot_ratings_user_id_fkey(username, aka, display_as)';
const _spotSelect = 'spot:spots!spot_ratings_spot_id_fkey(name)';
const _photoSpotSelect = 'spot:spots!spot_photos_spot_id_fkey(name)';

class AdminModerationService {
  AdminModerationService(this._client);
  final SupabaseClient _client;

  Future<List<SpotRatingDto>> fetchPendingRatings() async {
    final res = await _client
        .from('spot_ratings')
        .select('*, $_authorSelect, $_spotSelect')
        .eq('status', ReviewStatus.pending.dbValue)
        .order('created_at', ascending: false);
    return (res as List)
        .cast<Map<String, dynamic>>()
        .map(SpotRatingDto.fromMap)
        .toList(growable: false);
  }

  Future<List<SpotPhotoDto>> fetchPendingPhotos() async {
    final res = await _client
        .from('spot_photos')
        .select('*, $_photoSpotSelect')
        .eq('photo_status', PhotoStatus.pending.dbValue)
        .order('position');
    return (res as List)
        .cast<Map<String, dynamic>>()
        .map(SpotPhotoDto.fromMap)
        .toList(growable: false);
  }

  Future<void> setRatingStatus(String ratingId, ReviewStatus status) async {
    await _client
        .from('spot_ratings')
        .update({'status': status.dbValue})
        .eq('id', ratingId);
  }

  Future<void> setPhotoStatus(String photoId, PhotoStatus status) async {
    await _client
        .from('spot_photos')
        .update({'photo_status': status.dbValue})
        .eq('id', photoId);
  }
}

final adminModerationServiceProvider =
    Provider<AdminModerationService>((ref) {
  return AdminModerationService(ref.watch(supabaseClientProvider));
});
