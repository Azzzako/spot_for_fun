import 'package:spot_for_fun/domain/enums.dart';
import 'spot_photo_dto.dart';

class SpotDto {
  SpotDto({
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

  final List<SpotPhotoDto> photos;
  final String? authorName;

  factory SpotDto.fromMap(Map<String, dynamic> map) {
    return SpotDto(
      id: map['id'] as String,
      authorId: map['author_id'] as String,
      name: map['name'] as String,
      description: (map['description'] as String?) ?? '',
      lat: (map['lat'] as num).toDouble(),
      lng: (map['lng'] as num).toDouble(),
      type: SpotTypeX.fromDb(map['type']),
      difficulty: SpotDifficultyX.fromDb(map['difficulty']),
      bestTime: ((map['best_time'] as List?) ?? const [])
          .cast<String>()
          .map(BestTimeSlotX.fromDb)
          .toList(),
      safetyNotes: map['safety_notes'] as String?,
      status: SpotStatusX.fromDb(map['status']),
      rejectReason: map['reject_reason'] as String?,
      approvedBy: map['approved_by'] as String?,
      approvedAt: map['approved_at'] == null
          ? null
          : DateTime.parse(map['approved_at'] as String),
      avgRating: (map['avg_rating'] as num?)?.toDouble() ?? 0,
      ratingsCount: (map['ratings_count'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      photos: const [],
      authorName: null,
    );
  }
}
