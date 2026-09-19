import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:spot_for_fun/data/services/admin_moderation_service.dart';
import 'package:spot_for_fun/domain/enums.dart';
import 'package:spot_for_fun/domain/mappers/spot_mapper.dart';
import 'package:spot_for_fun/domain/mappers/spot_rating_mapper.dart';
import 'package:spot_for_fun/domain/models/spot.dart';
import 'package:spot_for_fun/domain/models/spot_rating.dart';

class AdminModerationRepository {
  AdminModerationRepository(this._service);
  final AdminModerationService _service;

  Future<List<SpotRating>> listPendingRatings() async {
    final dtos = await _service.fetchPendingRatings();
    return dtos.map((d) => d.toDomain()).toList(growable: false);
  }

  Future<List<SpotPhoto>> listPendingPhotos() async {
    final dtos = await _service.fetchPendingPhotos();
    return dtos.map((d) => d.toDomain()).toList(growable: false);
  }

  Future<void> approveRating(String id) =>
      _service.setRatingStatus(id, ReviewStatus.approved);

  Future<void> rejectRating(String id) =>
      _service.setRatingStatus(id, ReviewStatus.rejected);

  Future<void> approvePhoto(String id) =>
      _service.setPhotoStatus(id, PhotoStatus.approved);

  Future<void> rejectPhoto(String id) =>
      _service.setPhotoStatus(id, PhotoStatus.rejected);
}

final adminModerationRepositoryProvider =
    Provider<AdminModerationRepository>((ref) {
  return AdminModerationRepository(ref.watch(adminModerationServiceProvider));
});

final pendingRatingsProvider =
    FutureProvider.autoDispose<List<SpotRating>>((ref) async {
  final repo = ref.watch(adminModerationRepositoryProvider);
  return repo.listPendingRatings();
});

final pendingPhotosProvider =
    FutureProvider.autoDispose<List<SpotPhoto>>((ref) async {
  final repo = ref.watch(adminModerationRepositoryProvider);
  return repo.listPendingPhotos();
});
