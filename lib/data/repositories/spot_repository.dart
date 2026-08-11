import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'package:spot_for_fun/ui/core/providers/supabase_client_provider.dart';
import 'package:spot_for_fun/domain/enums.dart';
import 'package:spot_for_fun/domain/mappers/spot_mapper.dart';
import 'package:spot_for_fun/domain/models/spot.dart';
import 'package:spot_for_fun/data/models/spot_dto.dart';
import 'package:spot_for_fun/data/models/spot_photo_dto.dart';

class SpotFilter {
  const SpotFilter({
    this.types = const {},
    this.difficulties = const {},
    this.minRating = 0,
  });

  final Set<SpotType> types;
  final Set<SpotDifficulty> difficulties;
  final double minRating;

  bool get isEmpty =>
      types.isEmpty && difficulties.isEmpty && minRating == 0;

  SpotFilter copyWith({
    Set<SpotType>? types,
    Set<SpotDifficulty>? difficulties,
    double? minRating,
  }) {
    return SpotFilter(
      types: types ?? this.types,
      difficulties: difficulties ?? this.difficulties,
      minRating: minRating ?? this.minRating,
    );
  }
}

class SpotRepository {
  SpotRepository(this._client);
  final SupabaseClient _client;

  Future<List<Spot>> fetchApproved({SpotFilter filter = const SpotFilter()}) async {
    var query = _client
        .from('spots')
        .select('*, spot_photos(*)')
        .eq('status', 'approved');

    if (filter.types.isNotEmpty) {
      query = query.inFilter('type', filter.types.map((e) => e.dbValue).toList());
    }
    if (filter.difficulties.isNotEmpty) {
      query = query.inFilter(
        'difficulty',
        filter.difficulties.map((e) => e.dbValue).toList(),
      );
    }
    if (filter.minRating > 0) {
      query = query.gte('avg_rating', filter.minRating);
    }

    final res = await query.order('avg_rating', ascending: false);
    return (res as List)
        .cast<Map<String, dynamic>>()
        .map(_spotDtoFromRow)
        .map((d) => d.toDomain())
        .toList(growable: false);
  }

  Future<Spot> fetchById(String spotId) async {
    final res = await _client
        .from('spots')
        .select('*, spot_photos(*)')
        .eq('id', spotId)
        .maybeSingle();
    if (res == null) {
      throw StateError('Spot no encontrado');
    }
    return _spotDtoFromRow(res).toDomain();
  }

  Future<List<SpotPhoto>> fetchPhotos(String spotId) async {
    final res = await _client
        .from('spot_photos')
        .select()
        .eq('spot_id', spotId)
        .order('position');
    return (res as List)
        .cast<Map<String, dynamic>>()
        .map(SpotPhotoDto.fromMap)
        .map((d) => d.toDomain())
        .toList(growable: false);
  }

  Future<void> reportSpot({
    required String spotId,
    required String reason,
  }) async {
    await _client.from('spot_reports').insert({
      'spot_id': spotId,
      'reason': reason,
    });
  }

  Future<Spot> createSpot({
    required String name,
    required String description,
    required double lat,
    required double lng,
    required SpotType type,
    required SpotDifficulty difficulty,
    required List<BestTimeSlot> bestTime,
    String? safetyNotes,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('No hay sesion activa.');
    }
    final res = await _client
        .from('spots')
        .insert({
          'author_id': userId,
          'name': name,
          'description': description,
          'lat': lat,
          'lng': lng,
          'type': type.dbValue,
          'difficulty': difficulty.dbValue,
          'best_time': bestTime.map((t) => t.dbValue).toList(),
          'safety_notes': safetyNotes,
          'status': 'pending',
        })
        .select('*, spot_photos(*)')
        .single();
    return _spotDtoFromRow(res).toDomain();
  }

  Future<String> uploadSpotPhoto({
    required String spotId,
    required Uint8List bytes,
    required String ext,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('No hay sesion activa.');
    }
    final filename = '${const Uuid().v4()}.$ext';
    final path = '$userId/$spotId/$filename';

    await _client.storage
        .from('spot-photos')
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: 'image/$ext'),
        );

    return _client.storage
        .from('spot-photos')
        .getPublicUrl(path);
  }

  Future<SpotPhoto> attachSpotPhoto({
    required String spotId,
    required String url,
    required int position,
  }) async {
    final res = await _client
        .from('spot_photos')
        .insert({
          'spot_id': spotId,
          'url': url,
          'position': position,
        })
        .select()
        .single();
    return SpotPhotoDto.fromMap(res).toDomain();
  }

  SpotDto _spotDtoFromRow(Map<String, dynamic> map) {
    final photos = (map['spot_photos'] as List?)
            ?.cast<Map<String, dynamic>>()
            .map(SpotPhotoDto.fromMap)
            .toList() ??
        const <SpotPhotoDto>[];
    final base = SpotDto.fromMap(map);
    return SpotDto(
      id: base.id,
      authorId: base.authorId,
      name: base.name,
      description: base.description,
      lat: base.lat,
      lng: base.lng,
      type: base.type,
      difficulty: base.difficulty,
      bestTime: base.bestTime,
      safetyNotes: base.safetyNotes,
      status: base.status,
      rejectReason: base.rejectReason,
      approvedBy: base.approvedBy,
      approvedAt: base.approvedAt,
      avgRating: base.avgRating,
      ratingsCount: base.ratingsCount,
      createdAt: base.createdAt,
      updatedAt: base.updatedAt,
      photos: photos,
      authorName: base.authorName,
    );
  }
}

final spotRepositoryProvider = Provider<SpotRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SpotRepository(client);
});

final spotFilterProvider =
    StateProvider<SpotFilter>((ref) => const SpotFilter());

final approvedSpotsProvider = FutureProvider<List<Spot>>((ref) async {
  final repo = ref.watch(spotRepositoryProvider);
  final filter = ref.watch(spotFilterProvider);
  return repo.fetchApproved(filter: filter);
});
