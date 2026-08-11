class SpotRating {
  const SpotRating({
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

  SpotRating copyWith({
    String? id,
    String? spotId,
    String? userId,
    int? rating,
    String? comment,
    DateTime? createdAt,
    String? userName,
  }) {
    return SpotRating(
      id: id ?? this.id,
      spotId: spotId ?? this.spotId,
      userId: userId ?? this.userId,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
      userName: userName ?? this.userName,
    );
  }
}
