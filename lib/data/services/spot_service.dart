import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:spot_for_fun/data/models/spot_dto.dart';
import 'package:spot_for_fun/data/models/spot_photo_dto.dart';
import 'package:spot_for_fun/domain/enums.dart';

class SpotFilter {
  const SpotFilter({
    this.types = const {},
    this.difficulties = const {},
    this.bestTime = const {},
    this.minRating = 0,
  });

  final Set<SpotType> types;
  final Set<SpotDifficulty> difficulties;
  final Set<BestTimeSlot> bestTime;
  final double minRating;

  bool get isEmpty =>
      types.isEmpty &&
      difficulties.isEmpty &&
      bestTime.isEmpty &&
      minRating == 0;

  SpotFilter copyWith({
    Set<SpotType>? types,
    Set<SpotDifficulty>? difficulties,
    Set<BestTimeSlot>? bestTime,
    double? minRating,
  }) {
    return SpotFilter(
      types: types ?? this.types,
      difficulties: difficulties ?? this.difficulties,
      bestTime: bestTime ?? this.bestTime,
      minRating: minRating ?? this.minRating,
    );
  }
}

const _authorSelect =
    'author:profiles!spots_author_id_fkey(username, aka, display_as, avatar_url)';

class SpotService {
  SpotService(this._client);
  final SupabaseClient _client;

  Future<List<SpotDto>> fetchApproved({SpotFilter filter = const SpotFilter()}) async {
    var query = _client
        .from('spots')
        .select('*, $_authorSelect')
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
    if (filter.bestTime.isNotEmpty) {
      query = query.overlaps(
        'best_time',
        filter.bestTime.map((e) => e.dbValue).toList(),
      );
    }
    if (filter.minRating > 0) {
      query = query.gte('avg_rating', filter.minRating);
    }

    final res = await query.order('avg_rating', ascending: false);
    return (res as List)
        .cast<Map<String, dynamic>>()
        .map(_spotDtoFromRow)
        .toList(growable: false);
  }

  Future<SpotDto> fetchById(String spotId) async {
    final res = await _client
        .from('spots')
        .select('*, $_authorSelect')
        .eq('id', spotId)
        .maybeSingle();
    if (res == null) {
      throw StateError('Spot no encontrado');
    }
    return _spotDtoFromRow(res);
  }

  /// Bulk fetch spots by id. Used by the favorites tab to hydrate
  /// spot cards from a list of favorited ids.
  Future<List<SpotDto>> fetchByIds(List<String> ids) async {
    if (ids.isEmpty) return const [];
    final res = await _client
        .from('spots')
        .select('*, $_authorSelect')
        .inFilter('id', ids);
    return (res as List)
        .cast<Map<String, dynamic>>()
        .map(_spotDtoFromRow)
        .toList(growable: false);
  }

  Future<List<SpotPhotoDto>> fetchPhotos(String spotId) async {
    final res = await _client
        .from('spot_photos')
        .select()
        .eq('spot_id', spotId)
        .order('position');
    return (res as List)
        .cast<Map<String, dynamic>>()
        .map(SpotPhotoDto.fromMap)
        .toList(growable: false);
  }

  /// Photos attached to a given review. Used by the edit-review
  /// sheet to show the uploader what is already pending / approved.
  Future<List<SpotPhotoDto>> fetchPhotosForReview(String reviewId) async {
    final res = await _client
        .from('spot_photos')
        .select()
        .eq('review_id', reviewId)
        .order('position');
    return (res as List)
        .cast<Map<String, dynamic>>()
        .map(SpotPhotoDto.fromMap)
        .toList(growable: false);
  }

  Future<List<SpotDto>> fetchByAuthor(String authorId) async {
    final res = await _client
        .from('spots')
        .select('*, $_authorSelect')
        .eq('author_id', authorId)
        .order('created_at', ascending: false);
    return (res as List)
        .cast<Map<String, dynamic>>()
        .map(_spotDtoFromRow)
        .toList(growable: false);
  }

  Future<SpotDto> createSpot({
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
    final res = await _client
        .from('spots')
        .insert({
          'author_id': authorId,
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
        .select('*, spot_photos(*), $_authorSelect')
        .single();
    return _spotDtoFromRow(res);
  }

  Future<String> uploadSpotPhoto({
    required String userId,
    required String spotId,
    required String filename,
    required String ext,
    required Uint8List bytes,
  }) async {
    final path = '$userId/$spotId/$filename';
    await _client.storage.from('spot-photos').uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: 'image/$ext'),
        );
    return _client.storage.from('spot-photos').getPublicUrl(path);
  }

  Future<SpotPhotoDto> attachSpotPhoto({
    required String userId,
    required String spotId,
    required String url,
    required int position,
    String? reviewId,
    PhotoStatus photoStatus = PhotoStatus.approved,
  }) async {
    final res = await _client
        .from('spot_photos')
        .insert({
          'spot_id': spotId,
          'user_id': userId,
          'review_id': reviewId,
          'url': url,
          'position': position,
          'photo_status': photoStatus.dbValue,
        })
        .select()
        .single();
    return SpotPhotoDto.fromMap(res);
  }

  /// Combined upload + insert used by review and spot-author photo
  /// submissions. Status is forced to 'pending' so the moderator has
  /// to approve before it becomes visible to everyone.
  Future<SpotPhotoDto> submitPendingPhoto({
    required String userId,
    required String spotId,
    required Uint8List bytes,
    required String ext,
    String? reviewId,
    required int position,
  }) async {
    final filename =
        '${DateTime.now().microsecondsSinceEpoch}_${position.toString().padLeft(2, '0')}.$ext';
    final url = await uploadSpotPhoto(
      userId: userId,
      spotId: spotId,
      filename: filename,
      ext: ext,
      bytes: bytes,
    );
    return attachSpotPhoto(
      userId: userId,
      spotId: spotId,
      url: url,
      position: position,
      reviewId: reviewId,
      photoStatus: PhotoStatus.pending,
    );
  }

  Future<void> deleteSpotPhoto(String photoId) async {
    await _client.from('spot_photos').delete().eq('id', photoId);
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
      likesCount: (map['likes_count'] as num?)?.toInt() ?? 0,
      favoritesCount: (map['favorites_count'] as num?)?.toInt() ?? 0,
      createdAt: base.createdAt,
      updatedAt: base.updatedAt,
      markerKind: base.markerKind,
      photos: photos,
      authorDisplayName: _resolveAuthorDisplayName(map['author']),
      authorAvatarUrl: _resolveAuthorAvatar(map['author']),
    );
  }

  String? _resolveAuthorDisplayName(Object? raw) {
    if (raw is! Map) return null;
    final username = raw['username'] as String?;
    if (username == null || username.isEmpty) return null;
    final displayAs = DisplayAsX.fromDb(raw['display_as']);
    if (displayAs == DisplayAs.aka) {
      final aka = (raw['aka'] as String?)?.trim();
      if (aka != null && aka.isNotEmpty) return aka;
    }
    return username;
  }

  String? _resolveAuthorAvatar(Object? raw) {
    if (raw is! Map) return null;
    final url = raw['avatar_url'] as String?;
    if (url == null || url.isEmpty) return null;
    return url;
  }
}
