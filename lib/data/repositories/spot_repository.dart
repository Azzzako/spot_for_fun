import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:spot_for_fun/data/services/spot_service.dart';
import 'package:spot_for_fun/domain/enums.dart';
import 'package:spot_for_fun/domain/mappers/spot_mapper.dart';
import 'package:spot_for_fun/domain/models/spot.dart';
import 'package:spot_for_fun/ui/core/providers/supabase_client_provider.dart';

class SpotRepository {
  SpotRepository(this._service);
  final SpotService _service;

  Future<List<Spot>> fetchApproved({SpotFilter filter = const SpotFilter()}) async {
    final dtos = await _service.fetchApproved(filter: filter);
    return dtos.map((d) => d.toDomain()).toList(growable: false);
  }

  Future<Spot> fetchById(String spotId) async {
    final dto = await _service.fetchById(spotId);
    return dto.toDomain();
  }

  Future<List<SpotPhoto>> fetchPhotos(String spotId) async {
    final dtos = await _service.fetchPhotos(spotId);
    return dtos.map((d) => d.toDomain()).toList(growable: false);
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
    required String spotId,
    required String url,
    required int position,
  }) async {
    final dto = await _service.attachSpotPhoto(
      spotId: spotId,
      url: url,
      position: position,
    );
    return dto.toDomain();
  }
}

final spotFilterProvider =
    StateProvider<SpotFilter>((ref) => const SpotFilter());

final spotServiceProvider = Provider<SpotService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SpotService(client);
});

final spotRepositoryProvider = Provider<SpotRepository>((ref) {
  return SpotRepository(ref.watch(spotServiceProvider));
});

final approvedSpotsProvider = FutureProvider<List<Spot>>((ref) async {
  final repo = ref.watch(spotRepositoryProvider);
  final filter = ref.watch(spotFilterProvider);
  return repo.fetchApproved(filter: filter);
});
