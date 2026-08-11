class SpotRatingDto {
  SpotRatingDto({
    required this.id,
    required this.spotId,
    required this.userId,
    required this.rating,
    this.comment,
    required this.createdAt,
    this.userName,
  });

  final String id;
  final String spotId;
  final String userId;
  final int rating;
  final String? comment;
  final DateTime createdAt;
  final String? userName;

  factory SpotRatingDto.fromMap(Map<String, dynamic> map) {
    return SpotRatingDto(
      id: map['id'] as String,
      spotId: map['spot_id'] as String,
      userId: map['user_id'] as String,
      rating: (map['rating'] as num).toInt(),
      comment: map['comment'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      userName: map['user_name'] as String?,
    );
  }
}
