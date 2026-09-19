import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'package:spot_for_fun/data/services/spot_service.dart';
import 'package:spot_for_fun/data/repositories/auth_provider.dart';
import 'package:spot_for_fun/data/models/spot_dto.dart';
import 'package:spot_for_fun/data/models/spot_photo_dto.dart';
import 'package:spot_for_fun/domain/enums.dart';
import 'package:spot_for_fun/domain/mappers/spot_mapper.dart';
import 'package:spot_for_fun/domain/models/spot.dart';
import 'package:spot_for_fun/ui/core/providers/supabase_client_provider.dart';

class SpotRepository {
  SpotRepository(this._service, this._client);
  final SpotService _service;
  final SupabaseClient _client;

  Future<List<Spot>> fetchApproved({SpotFilter filter = const SpotFilter()}) async {
    final dtos = await _service.fetchApproved(filter: filter);
    return _withVisiblePhotos(dtos);
  }

  Future<List<Spot>> fetchByAuthor(String authorId) async {
    final dtos = await _service.fetchByAuthor(authorId);
    return _withVisiblePhotos(dtos);
  }

  Future<List<Spot>> _withVisiblePhotos(List<SpotDto> dtos) async {
    return Future.wait(
      dtos.map((dto) async {
        final spot = dto.toDomain();
        final photos = await fetchVisiblePhotos(spot.id);
        return spot.copyWith(photos: photos);
      }),
    );
  }

  Future<Spot> fetchById(String spotId) async {
    final dto = await _service.fetchById(spotId);
    return dto.toDomain();
  }

  Future<List<SpotPhoto>> fetchPhotos(String spotId) async {
    final dtos = await _service.fetchPhotos(spotId);
    return dtos.map((d) => d.toDomain()).toList(growable: false);
  }

  Future<List<SpotPhoto>> fetchPhotosForReview(String reviewId) async {
    final dtos = await _service.fetchPhotosForReview(reviewId);
    return dtos.map((d) => d.toDomain()).toList(growable: false);
  }

  /// Returns the photos the current user should see on a spot:
  /// every approved photo + their own pending uploads. Uses explicit
  /// filters so the spot_photos RLS doesn't accidentally hide
  /// approved rows (Supabase's policy on this table wasn't being
  /// applied reliably from PostgREST).
  Future<List<SpotPhoto>> fetchVisiblePhotos(String spotId) async {
    final approvedRes = await _client
        .from('spot_photos')
        .select()
        .eq('spot_id', spotId)
        .eq('photo_status', PhotoStatus.approved.dbValue)
        .order('position');
    final approved = (approvedRes as List)
        .cast<Map<String, dynamic>>()
        .map(SpotPhotoDto.fromMap)
        .map((d) => d.toDomain())
        .toList();

    final uid = _client.auth.currentUser?.id;
    if (uid == null) return approved;

    final ownPendingRes = await _client
        .from('spot_photos')
        .select()
        .eq('spot_id', spotId)
        .eq('photo_status', PhotoStatus.pending.dbValue)
        .eq('user_id', uid)
        .order('position');
    final ownPending = (ownPendingRes as List)
        .cast<Map<String, dynamic>>()
        .map(SpotPhotoDto.fromMap)
        .map((d) => d.toDomain())
        .toList();

    return [...approved, ...ownPending];
  }

  Future<void> reportSpot({
    required String spotId,
    required String reason,
  }) async {
    await _service.reportSpot(spotId: spotId, reason: reason);
  }

  Future<Spot> createSpot({
    required String authorId,
    required String name,
    required String description,
    required double lat,
    required double lng,
    required SpotType type,
    required SpotDifficulty difficulty,
    required List<BestTimeSlot> bestTime,
    String? safetyNotes,
  }) async {
    final dto = await _service.createSpot(
      authorId: authorId,
      name: name,
      description: description,
      lat: lat,
      lng: lng,
      type: type,
      difficulty: difficulty,
      bestTime: bestTime,
      safetyNotes: safetyNotes,
    );
    return dto.toDomain();
  }

  Future<String> uploadSpotPhoto({
    required String userId,
    required String spotId,
    required Uint8List bytes,
    required String ext,
  }) async {
    final filename = '${const Uuid().v4()}.$ext';
    return _service.uploadSpotPhoto(
      userId: userId,
      spotId: spotId,
      filename: filename,
      ext: ext,
      bytes: bytes,
    );
  }

  Future<SpotPhoto> attachSpotPhoto({
    required String userId,
    required String spotId,
    required String url,
    required int position,
    String? reviewId,
    PhotoStatus photoStatus = PhotoStatus.approved,
  }) async {
    final dto = await _service.attachSpotPhoto(
      userId: userId,
      spotId: spotId,
      url: url,
      position: position,
      reviewId: reviewId,
      photoStatus: photoStatus,
    );
    return dto.toDomain();
  }

  /// Upload + attach in one call, with photo_status forced to
  /// 'pending'. Used by review submissions and spot-author extras.
  Future<SpotPhoto> submitPendingPhoto({
    required String userId,
    required String spotId,
    required Uint8List bytes,
    required String ext,
    String? reviewId,
    required int position,
  }) async {
    final dto = await _service.submitPendingPhoto(
      userId: userId,
      spotId: spotId,
      bytes: bytes,
      ext: ext,
      reviewId: reviewId,
      position: position,
    );
    return dto.toDomain();
  }

  /// Deletes a pending photo. RLS only allows this for the uploader
  /// while status='pending'.
  Future<void> deleteSpotPhoto(String photoId) async {
    await _service.deleteSpotPhoto(photoId);
  }
}

final spotFilterProvider =
    StateProvider<SpotFilter>((ref) => const SpotFilter());

final spotServiceProvider = Provider<SpotService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SpotService(client);
});

final spotRepositoryProvider = Provider<SpotRepository>((ref) {
  return SpotRepository(
    ref.watch(spotServiceProvider),
    ref.watch(supabaseClientProvider),
  );
});

final approvedSpotsProvider = FutureProvider<List<Spot>>((ref) async {
  final repo = ref.watch(spotRepositoryProvider);
  final filter = ref.watch(spotFilterProvider);
  return repo.fetchApproved(filter: filter);
});

final mySpotsProvider =
    FutureProvider.autoDispose<List<Spot>>((ref) async {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) return const [];
  final repo = ref.watch(spotRepositoryProvider);
  return repo.fetchByAuthor(uid);
});

/// Photos visible to the current user on a given spot: every
/// approved photo plus their own pending uploads. Uses explicit
/// filters because the spot_photos RLS isn't being applied
/// consistently by PostgREST.
final spotPhotosVisibleProvider = FutureProvider.family
    .autoDispose<List<SpotPhoto>, String>((ref, spotId) async {
  final repo = ref.watch(spotRepositoryProvider);
  return repo.fetchVisiblePhotos(spotId);
});
