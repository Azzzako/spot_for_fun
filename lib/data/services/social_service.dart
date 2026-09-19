import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:spot_for_fun/data/models/spot_favorite_dto.dart';
import 'package:spot_for_fun/data/models/spot_like_dto.dart';
import 'package:spot_for_fun/ui/core/providers/supabase_client_provider.dart';

class SocialService {
  SocialService(this._client);
  final SupabaseClient _client;

  Future<List<SpotLikeDto>> fetchMyLikes() async {
    final res = await _client
        .from('spot_likes')
        .select()
        .order('created_at', ascending: false);
    return (res as List)
        .cast<Map<String, dynamic>>()
        .map(SpotLikeDto.fromMap)
        .toList(growable: false);
  }

  Future<List<SpotFavoriteDto>> fetchMyFavorites() async {
    final res = await _client
        .from('spot_favorites')
        .select()
        .order('created_at', ascending: false);
    return (res as List)
        .cast<Map<String, dynamic>>()
        .map(SpotFavoriteDto.fromMap)
        .toList(growable: false);
  }

  Future<void> likeSpot(String spotId) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw StateError('No autenticado');
    await _client.from('spot_likes').insert({
      'spot_id': spotId,
      'user_id': uid,
    });
  }

  Future<void> unlikeSpot(String spotId) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw StateError('No autenticado');
    await _client
        .from('spot_likes')
        .delete()
        .eq('spot_id', spotId)
        .eq('user_id', uid);
  }

  Future<void> favoriteSpot(String spotId) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw StateError('No autenticado');
    await _client.from('spot_favorites').insert({
      'spot_id': spotId,
      'user_id': uid,
    });
  }

  Future<void> unfavoriteSpot(String spotId) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw StateError('No autenticado');
    await _client
        .from('spot_favorites')
        .delete()
        .eq('spot_id', spotId)
        .eq('user_id', uid);
  }
}

final socialServiceProvider = Provider<SocialService>((ref) {
  return SocialService(ref.watch(supabaseClientProvider));
});
