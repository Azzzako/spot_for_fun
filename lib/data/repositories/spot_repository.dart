import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'package:spot_for_fun/data/local/spot_cache.dart';
import 'package:spot_for_fun/data/services/spot_service.dart';
import 'package:spot_for_fun/data/repositories/auth_provider.dart';
import 'package:spot_for_fun/data/repositories/social_repository.dart';
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

  Future<List<Spot>> fetchByAuthor(
    String authorId, {
    Set<String> likedIds = const {},
    Set<String> favoritedIds = const {},
  }) async {
    final dtos = await _service.fetchByAuthor(authorId);
    return _hydrate(dtos, likedIds, favoritedIds);
  }

  /// List cards only need the cover (spots.cover_url), so no photo
  /// queries here; the detail screen loads all photos on its own.
  List<Spot> _hydrate(
    List<SpotDto> dtos,
    Set<String> likedIds,
    Set<String> favoritedIds,
  ) {
    return [
      for (final dto in dtos)
        dto.toDomain().copyWith(
          isLiked: likedIds.contains(dto.id),
          isFavorited: favoritedIds.contains(dto.id),
        ),
    ];
  }

  /// The spot row only; its photos come from [fetchVisiblePhotos] and
  /// the favorite flag from myFavoritedSpotIdsProvider.
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
    final approved = PhotoStatus.approved.dbValue;
    final pending = PhotoStatus.pending.dbValue;
    final uid = _client.auth.currentUser?.id;
    final query = _client.from('spot_photos').select().eq('spot_id', spotId);
    final res =
        await (uid == null
                ? query.eq('photo_status', approved)
                : query.or(
                    'photo_status.eq.$approved,'
                    'and(photo_status.eq.$pending,user_id.eq.$uid)',
                  ))
            .order('position');
    final photos = (res as List)
        .cast<Map<String, dynamic>>()
        .map(SpotPhotoDto.fromMap)
        .map((d) => d.toDomain())
        .toList();
    // Approved first, then the user's own pending ones, each by position.
    return [
      ...photos.where((p) => p.photoStatus == PhotoStatus.approved),
      ...photos.where((p) => p.photoStatus != PhotoStatus.approved),
    ];
  }

  /// Hydrates Spot cards from a list of favorited spot ids. Photos
  /// are loaded per-spot and the favorited flag is stamped on each
  /// (liked is left at its fetched default — out of scope here).
  Future<List<Spot>> fetchFavoritedSpots(List<String> spotIds) async {
    if (spotIds.isEmpty) return const [];
    final dtos = await _service.fetchByIds(spotIds);
    return _hydrate(dtos, const {}, spotIds.toSet());
  }

  Future<void> reportSpot({
    required String spotId,
    required String reason,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw StateError('Necesitas iniciar sesión para reportar');
    await _service.reportSpot(reporterId: uid, spotId: spotId, reason: reason);
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

final spotFilterProvider = StateProvider<SpotFilter>(
  (ref) => const SpotFilter(),
);

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

final spotCatalogProvider = NotifierProvider<SpotCatalog, SpotCatalogState>(
  SpotCatalog.new,
);

/// Spots in the local catalog that pass the filter sheet, with the
/// favorite flag. Filtering happens on the phone, so it's instant and
/// works offline. The map further trims this to its range circle.
final approvedSpotsProvider = Provider<List<Spot>>((ref) {
  final catalog = ref.watch(spotCatalogProvider);
  final filter = ref.watch(spotFilterProvider);
  final favs = ref.watch(myFavoritedSpotIdsProvider).valueOrNull ?? const {};
  return [
    for (final s in catalog.spots)
      if (_matches(filter, s)) s.copyWith(isFavorited: favs.contains(s.id)),
  ];
});

bool _matches(SpotFilter f, Spot s) {
  if (f.types.isNotEmpty && !f.types.contains(s.type)) return false;
  if (f.difficulties.isNotEmpty && !f.difficulties.contains(s.difficulty)) {
    return false;
  }
  if (f.bestTime.isNotEmpty && !s.bestTime.any(f.bestTime.contains)) {
    return false;
  }
  if (f.minRating > 0 && s.avgRating < f.minRating) return false;
  return true;
}

final mySpotsProvider = FutureProvider.autoDispose<List<Spot>>((ref) async {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) return const [];
  final repo = ref.watch(spotRepositoryProvider);
  final favs = await ref.watch(myFavoritedSpotIdsProvider.future);
  return repo.fetchByAuthor(uid, favoritedIds: favs);
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

/// Spots the current user has favorited. Backed by the
/// [myFavoritedSpotIdsProvider] so toggles invalidate the list.
final myFavoriteSpotsProvider = FutureProvider.autoDispose<List<Spot>>((
  ref,
) async {
  final repo = ref.watch(spotRepositoryProvider);
  final ids = await ref.watch(myFavoritedSpotIdsProvider.future);
  // Reuse what the map already downloaded; only fetch the rest.
  final cached = {for (final s in ref.read(spotCatalogProvider).spots) s.id: s};
  final missing = [
    for (final id in ids)
      if (!cached.containsKey(id)) id,
  ];
  final fetched = await repo.fetchFavoritedSpots(missing);
  return [
    for (final id in ids)
      if (cached[id] != null) cached[id]!.copyWith(isFavorited: true),
    ...fetched,
  ];
});

@immutable
class SpotCatalogState {
  const SpotCatalogState({
    this.spots = const [],
    this.ready = false,
    this.loading = false,
    this.failed = false,
  });

  /// Every spot downloaded so far (all areas), from the local cache.
  final List<Spot> spots;

  /// The on-disk cache has been read.
  final bool ready;

  /// An area is being downloaded.
  final bool loading;

  /// The last download failed (offline, server error…).
  final bool failed;
}

/// Spots by map area, kept on the phone between launches.
///
/// The map asks for the area it shows ([ensureArea]); areas already
/// downloaded less than [freshFor] ago are served from the cache, others
/// are fetched with spots_in_radius and merged. Each download also drops
/// cached spots inside that circle that the server no longer returns
/// (rejected or deleted).
class SpotCatalog extends Notifier<SpotCatalogState> {
  static const freshFor = Duration(minutes: 10);
  static const _serverLimit = 500;

  final _cache = SpotCache();
  SpotCacheData _data = SpotCacheData();
  final _spots = <String, Spot>{};
  late Future<void> _cacheLoaded;
  bool _busy = false;
  ({double lat, double lng, double needM, double fetchM, bool force})? _queued;

  @override
  SpotCatalogState build() {
    _cacheLoaded = _loadCache();
    return const SpotCatalogState();
  }

  Future<void> _loadCache() async {
    _data = await _cache.load();
    final service = ref.read(spotServiceProvider);
    final broken = <String>[];
    for (final entry in _data.rows.entries) {
      try {
        _spots[entry.key] = service.parseSpotRow(entry.value).toDomain();
      } catch (_) {
        // A row from an older schema: drop it, it'll be downloaded again.
        broken.add(entry.key);
      }
    }
    broken.forEach(_data.rows.remove);
    _emit(ready: true);
  }

  void _emit({bool? ready, bool? loading, bool? failed}) {
    state = SpotCatalogState(
      spots: _spots.values.toList(growable: false),
      ready: ready ?? state.ready,
      loading: loading ?? state.loading,
      failed: failed ?? state.failed,
    );
  }

  static const _distance = Distance();

  bool _isCovered(double lat, double lng, double radiusM) {
    final now = DateTime.now();
    final center = LatLng(lat, lng);
    for (final a in _data.areas) {
      if (now.difference(a.fetchedAt) > freshFor) continue;
      final d = _distance.as(LengthUnit.Meter, center, LatLng(a.lat, a.lng));
      if (d + radiusM <= a.radiusM) return true;
    }
    return false;
  }

  /// Makes sure the spots within [needM] of this point are loaded. When
  /// they aren't, downloads the bigger [fetchM] circle so nearby moves are
  /// already covered. Cheap to call on every camera stop: covered, fresh
  /// areas return immediately. While a download runs, only the latest
  /// request is kept and run after it.
  Future<void> ensureArea(
    double lat,
    double lng, {
    required double needM,
    required double fetchM,
    bool force = false,
  }) async {
    await _cacheLoaded;
    if (!force && _isCovered(lat, lng, needM)) return;
    if (_busy) {
      _queued = (
        lat: lat,
        lng: lng,
        needM: needM,
        fetchM: fetchM,
        force: force,
      );
      return;
    }
    _busy = true;
    _emit(loading: true);
    try {
      final service = ref.read(spotServiceProvider);
      final rows = await service.fetchInRadiusRaw(
        lat: lat,
        lng: lng,
        radiusMeters: fetchM,
      );
      final returned = {for (final r in rows) r['id'] as String};
      // Rows come nearest first. A full page cut off the farthest spots,
      // so only the circle up to the last one returned is really loaded.
      final center = LatLng(lat, lng);
      final coveredM = rows.length < _serverLimit
          ? fetchM
          : _distance.as(
              LengthUnit.Meter,
              center,
              LatLng(
                (rows.last['lat'] as num).toDouble(),
                (rows.last['lng'] as num).toDouble(),
              ),
            );
      final gone = [
        for (final s in _spots.values)
          if (!returned.contains(s.id) &&
              _distance.as(LengthUnit.Meter, center, LatLng(s.lat, s.lng)) <
                  coveredM)
            s.id,
      ];
      for (final id in gone) {
        _spots.remove(id);
        _data.rows.remove(id);
      }
      for (final row in rows) {
        final id = row['id'] as String;
        _data.rows[id] = row;
        _spots[id] = service.parseSpotRow(row).toDomain();
      }
      _data.areas.add(
        CachedArea(
          lat: lat,
          lng: lng,
          radiusM: coveredM,
          fetchedAt: DateTime.now(),
        ),
      );
      if (_data.areas.length > SpotCache.maxAreas) {
        _data.areas.removeRange(0, _data.areas.length - SpotCache.maxAreas);
      }
      _emit(loading: false, failed: false);
      await _cache.save(_data);
    } catch (e) {
      debugPrint('[SpotCatalog] area download failed: $e');
      _emit(loading: false, failed: true);
    } finally {
      _busy = false;
      final next = _queued;
      _queued = null;
      if (next != null) {
        await ensureArea(
          next.lat,
          next.lng,
          needM: next.needM,
          fetchM: next.fetchM,
          force: next.force,
        );
      }
    }
  }
}
