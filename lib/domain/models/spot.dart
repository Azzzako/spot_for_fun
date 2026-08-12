import 'package:spot_for_fun/domain/enums.dart';

class Spot {
  const Spot({
    required this.id,
    required this.authorId,
    required this.name,
    required this.description,
    required this.lat,
    required this.lng,
    required this.type,
    required this.difficulty,
    required this.bestTime,
    this.safetyNotes,
    required this.status,
    this.rejectReason,
    this.approvedBy,
    this.approvedAt,
    required this.avgRating,
    required this.ratingsCount,
    required this.createdAt,
    required this.updatedAt,
    this.markerKind,
    this.photos = const [],
    this.authorName,
  });

  final String id;
  final String authorId;
  final String name;
  final String description;
  final double lat;
  final double lng;
  final SpotType type;
  final SpotDifficulty difficulty;
  final List<BestTimeSlot> bestTime;
  final String? safetyNotes;
  final SpotStatus status;
  final String? rejectReason;
  final String? approvedBy;
  final DateTime? approvedAt;
  final double avgRating;
  final int ratingsCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final MarkerKind? markerKind;
  final List<SpotPhoto> photos;
  final String? authorName;

  bool get isApproved => status == SpotStatus.approved;
  bool get isPending => status == SpotStatus.pending;
  bool get isRejected => status == SpotStatus.rejected;
  bool get hasRating => ratingsCount > 0;
  int get ratingStars => avgRating.round();

  Spot copyWith({
    String? id,
    String? authorId,
    String? name,
    String? description,
    double? lat,
    double? lng,
    SpotType? type,
    SpotDifficulty? difficulty,
    List<BestTimeSlot>? bestTime,
    String? safetyNotes,
    SpotStatus? status,
    String? rejectReason,
    String? approvedBy,
    DateTime? approvedAt,
    double? avgRating,
    int? ratingsCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    MarkerKind? markerKind,
    List<SpotPhoto>? photos,
    String? authorName,
    bool clearMarkerKind = false,
  }) {
    return Spot(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      name: name ?? this.name,
      description: description ?? this.description,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      type: type ?? this.type,
      difficulty: difficulty ?? this.difficulty,
      bestTime: bestTime ?? this.bestTime,
      safetyNotes: safetyNotes ?? this.safetyNotes,
      status: status ?? this.status,
      rejectReason: rejectReason ?? this.rejectReason,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      avgRating: avgRating ?? this.avgRating,
      ratingsCount: ratingsCount ?? this.ratingsCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      markerKind: clearMarkerKind ? null : (markerKind ?? this.markerKind),
      photos: photos ?? this.photos,
      authorName: authorName ?? this.authorName,
    );
  }
}

class SpotPhoto {
  const SpotPhoto({
    required this.id,
    required this.spotId,
    required this.url,
    required this.position,
  });

  final String id;
  final String spotId;
  final String url;
  final int position;

  SpotPhoto copyWith({
    String? id,
    String? spotId,
    String? url,
    int? position,
  }) {
    return SpotPhoto(
      id: id ?? this.id,
      spotId: spotId ?? this.spotId,
      url: url ?? this.url,
      position: position ?? this.position,
    );
  }
}
