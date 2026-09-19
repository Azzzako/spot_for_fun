import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:spot_for_fun/data/services/social_service.dart';
import 'package:spot_for_fun/data/repositories/auth_provider.dart';
import 'package:spot_for_fun/domain/mappers/spot_favorite_mapper.dart';
import 'package:spot_for_fun/domain/mappers/spot_like_mapper.dart';
import 'package:spot_for_fun/domain/models/spot_favorite.dart';
import 'package:spot_for_fun/domain/models/spot_like.dart';

class SocialRepository {
  SocialRepository(this._service);
  final SocialService _service;

  Future<List<SpotLike>> myLikes() async {
    final dtos = await _service.fetchMyLikes();
    return dtos.map((d) => d.toDomain()).toList(growable: false);
  }

  Future<List<SpotFavorite>> myFavorites() async {
    final dtos = await _service.fetchMyFavorites();
    return dtos.map((d) => d.toDomain()).toList(growable: false);
  }

  Future<void> like(String spotId) => _service.likeSpot(spotId);
  Future<void> unlike(String spotId) => _service.unlikeSpot(spotId);
  Future<void> favorite(String spotId) => _service.favoriteSpot(spotId);
  Future<void> unfavorite(String spotId) => _service.unfavoriteSpot(spotId);
}

final socialRepositoryProvider = Provider<SocialRepository>((ref) {
  return SocialRepository(ref.watch(socialServiceProvider));
});

/// Set of spot IDs the current user has liked. Empty when not signed in.
final myLikedSpotIdsProvider =
    FutureProvider.autoDispose<Set<String>>((ref) async {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) return const <String>{};
  final repo = ref.watch(socialRepositoryProvider);
  final likes = await repo.myLikes();
  return likes.map((l) => l.spotId).toSet();
});

/// Set of spot IDs the current user has favorited.
final myFavoritedSpotIdsProvider =
    FutureProvider.autoDispose<Set<String>>((ref) async {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) return const <String>{};
  final repo = ref.watch(socialRepositoryProvider);
  final favs = await repo.myFavorites();
  return favs.map((f) => f.spotId).toSet();
});
