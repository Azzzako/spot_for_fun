import 'package:spot_for_fun/domain/enums.dart';

class SpotRatingDto {
  SpotRatingDto({
    required this.id,
    required this.spotId,
    required this.userId,
    required this.rating,
    this.comment,
    required this.createdAt,
    this.userName,
    this.userDisplayName,
    this.userAka,
    this.userDisplayAs = DisplayAs.username,
    this.status = ReviewStatus.pending,
    this.edited = false,
    this.editedAt,
    this.spotName,
  });

  final String id;
  final String spotId;
  final String userId;
  final int rating;
  final String? comment;
  final DateTime createdAt;
  final String? userName;
  final String? userDisplayName;
  final String? userAka;
  final DisplayAs userDisplayAs;
  final ReviewStatus status;
  final bool edited;
  final DateTime? editedAt;
  final String? spotName;

  factory SpotRatingDto.fromMap(Map<String, dynamic> map) {
    final author = map['author'] is Map
        ? Map<String, dynamic>.from(map['author'] as Map)
        : null;
    final spot = map['spot'] is Map
        ? Map<String, dynamic>.from(map['spot'] as Map)
        : null;
    return SpotRatingDto(
      id: map['id'] as String,
      spotId: map['spot_id'] as String,
      userId: map['user_id'] as String,
      rating: (map['rating'] as num).toInt(),
      comment: map['comment'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      userName: author?['username'] as String? ?? map['user_name'] as String?,
      userDisplayName: author?['username'] as String?,
      userAka: author?['aka'] as String?,
      userDisplayAs: DisplayAsX.fromDb(author?['display_as']),
      status: ReviewStatusX.fromDb(map['status']),
      edited: (map['edited'] as bool?) ?? false,
      editedAt: map['edited_at'] == null
          ? null
          : DateTime.parse(map['edited_at'] as String),
      spotName: spot?['name'] as String?,
    );
  }
}
