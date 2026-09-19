class SpotLikeDto {
  SpotLikeDto({
    required this.spotId,
    required this.userId,
    required this.createdAt,
  });

  final String spotId;
  final String userId;
  final DateTime createdAt;

  factory SpotLikeDto.fromMap(Map<String, dynamic> map) {
    return SpotLikeDto(
      spotId: map['spot_id'] as String,
      userId: map['user_id'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
