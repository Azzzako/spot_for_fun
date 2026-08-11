import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/providers/supabase_client_provider.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/models/spot.dart';
import '../../../shared/models/spot_photo.dart';

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
    return _mapList(res as List);
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
    return _mapOne(res);
  }

  Future<List<SpotPhoto>> fetchPhotos(String spotId) async {
    final res = await _client
        .from('spot_photos')
        .select()
        .eq('spot_id', spotId)
        .order('position');
    return (res as List)
        .cast<Map<String, dynamic>>()
        .map(SpotPhoto.fromMap)
        .toList();
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

  Spot _mapOne(Map<String, dynamic> map) {
    final photos = (map['spot_photos'] as List?)
            ?.cast<Map<String, dynamic>>()
            .map(SpotPhoto.fromMap)
            .toList() ??
        const <SpotPhoto>[];
    final spot = Spot.fromMap(map);
    return Spot(
      id: spot.id,
      authorId: spot.authorId,
      name: spot.name,
      description: spot.description,
      lat: spot.lat,
      lng: spot.lng,
      type: spot.type,
      difficulty: spot.difficulty,
      bestTime: spot.bestTime,
      safetyNotes: spot.safetyNotes,
      status: spot.status,
      rejectReason: spot.rejectReason,
      approvedBy: spot.approvedBy,
      approvedAt: spot.approvedAt,
      avgRating: spot.avgRating,
      ratingsCount: spot.ratingsCount,
      createdAt: spot.createdAt,
      updatedAt: spot.updatedAt,
      photos: photos,
    );
  }

  List<Spot> _mapList(List data) {
    return data
        .cast<Map<String, dynamic>>()
        .map(_mapOne)
        .toList(growable: false);
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
