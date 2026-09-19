class SpotFavoriteDto {
  SpotFavoriteDto({
    required this.spotId,
    required this.userId,
    required this.createdAt,
  });

  final String spotId;
  final String userId;
  final DateTime createdAt;

  factory SpotFavoriteDto.fromMap(Map<String, dynamic> map) {
    return SpotFavoriteDto(
      spotId: map['spot_id'] as String,
      userId: map['user_id'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
