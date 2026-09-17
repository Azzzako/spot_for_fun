import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:spot_for_fun/data/repositories/auth_provider.dart';
import 'package:spot_for_fun/data/services/spot_rating_service.dart';
import 'package:spot_for_fun/domain/mappers/spot_rating_mapper.dart';
import 'package:spot_for_fun/domain/models/spot_rating.dart';

class SpotRatingRepository {
  SpotRatingRepository(this._service);
  final SpotRatingService _service;

  Future<List<SpotRating>> fetchVisibleForSpot(String spotId) async {
    final dtos = await _service.fetchVisibleForSpot(spotId);
    return dtos.map((d) => d.toDomain()).toList(growable: false);
  }

  Future<SpotRating?> fetchMine(String spotId) async {
    final dto = await _service.fetchMine(spotId);
    return dto?.toDomain();
  }

  Future<SpotRating> create({
    required String spotId,
    required String userId,
    required int rating,
    required String comment,
  }) async {
    final dto = await _service.create(
      spotId: spotId,
      userId: userId,
      rating: rating,
      comment: comment,
    );
    return dto.toDomain();
  }

  Future<SpotRating> update({
    required String id,
    required int rating,
    required String comment,
  }) async {
    final dto = await _service.update(
      id: id,
      rating: rating,
      comment: comment,
    );
    return dto.toDomain();
  }

  Future<List<SpotRating>> fetchByUser(String userId) async {
    final dtos = await _service.fetchByUser(userId);
    return dtos.map((d) => d.toDomain()).toList(growable: false);
  }
}

final spotRatingRepositoryProvider = Provider<SpotRatingRepository>((ref) {
  return SpotRatingRepository(ref.watch(spotRatingServiceProvider));
});

final myRatingsProvider = FutureProvider.autoDispose<List<SpotRating>>((ref) async {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) return const <SpotRating>[];
  final repo = ref.watch(spotRatingRepositoryProvider);
  return repo.fetchByUser(uid);
});
