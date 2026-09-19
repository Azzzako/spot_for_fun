import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:spot_for_fun/data/models/spot_rating_dto.dart';
import 'package:spot_for_fun/ui/core/providers/supabase_client_provider.dart';

const _authorSelect =
    'author:profiles!spot_ratings_user_id_fkey(username, aka, display_as, avatar_url)';
const _spotSelect = 'spot:spots!spot_ratings_spot_id_fkey(name)';

class SpotRatingService {
  SpotRatingService(this._client);
  final SupabaseClient _client;

  /// Public reviews for a spot: approved + own (any status). RLS does
  /// the heavy lifting; we still pass a status filter so the query
  /// stays explicit.
  Future<List<SpotRatingDto>> fetchVisibleForSpot(String spotId) async {
    final userId = _client.auth.currentUser?.id;
    final filter = _client
        .from('spot_ratings')
        .select('*, $_authorSelect, $_spotSelect')
        .eq('spot_id', spotId);
    final filtered = userId != null
        ? filter.or('status.eq.approved,user_id.eq.$userId')
        : filter.eq('status', 'approved');
    final res = await filtered.order('created_at', ascending: false);
    return (res as List)
        .cast<Map<String, dynamic>>()
        .map(SpotRatingDto.fromMap)
        .toList(growable: false);
  }

  Future<SpotRatingDto?> fetchMine(String spotId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;
    final res = await _client
        .from('spot_ratings')
        .select('*, $_authorSelect, $_spotSelect')
        .eq('spot_id', spotId)
        .eq('user_id', userId)
        .maybeSingle();
    if (res == null) return null;
    return SpotRatingDto.fromMap(res);
  }

  Future<SpotRatingDto> create({
    required String spotId,
    required String userId,
    required int rating,
    required String comment,
  }) async {
    final res = await _client
        .from('spot_ratings')
        .insert({
          'spot_id': spotId,
          'user_id': userId,
          'rating': rating,
          'comment': comment,
        })
        .select('*, $_authorSelect, $_spotSelect')
        .single();
    return SpotRatingDto.fromMap(res);
  }

  Future<SpotRatingDto> update({
    required String id,
    required int rating,
    required String comment,
  }) async {
    final res = await _client
        .from('spot_ratings')
        .update({
          'rating': rating,
          'comment': comment,
        })
        .eq('id', id)
        .select('*, $_authorSelect, $_spotSelect')
        .single();
    return SpotRatingDto.fromMap(res);
  }

  /// All reviews authored by the given user (any status). Used by the
  /// profile > Reseñas tab.
  Future<List<SpotRatingDto>> fetchByUser(String userId) async {
    final res = await _client
        .from('spot_ratings')
        .select('*, $_authorSelect, $_spotSelect')
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return (res as List)
        .cast<Map<String, dynamic>>()
        .map(SpotRatingDto.fromMap)
        .toList(growable: false);
  }
}

final spotRatingServiceProvider = Provider<SpotRatingService>((ref) {
  return SpotRatingService(ref.watch(supabaseClientProvider));
});
