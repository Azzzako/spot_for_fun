import 'package:spot_for_fun/domain/enums.dart';

class SpotRating {
  const SpotRating({
    required this.id,
    required this.spotId,
    required this.userId,
    required this.rating,
    this.comment,
    required this.createdAt,
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
  final String? userDisplayName;
  final String? userAka;
  final DisplayAs userDisplayAs;
  final ReviewStatus status;
  final bool edited;
  final DateTime? editedAt;
  final String? spotName;

  /// Display name honoring the author's preference (aka if available
  /// and chosen, otherwise username).
  String get authorDisplayName {
    final username = userDisplayName;
    if (username == null || username.isEmpty) return 'Alguien';
    if (userDisplayAs == DisplayAs.aka) {
      final aka = userAka?.trim();
      if (aka != null && aka.isNotEmpty) return aka;
    }
    return username;
  }

  SpotRating copyWith({
    String? id,
    String? spotId,
    String? userId,
    int? rating,
    String? comment,
    DateTime? createdAt,
    String? userDisplayName,
    String? userAka,
    DisplayAs? userDisplayAs,
    ReviewStatus? status,
    bool? edited,
    DateTime? editedAt,
    String? spotName,
  }) {
    return SpotRating(
      id: id ?? this.id,
      spotId: spotId ?? this.spotId,
      userId: userId ?? this.userId,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
      userDisplayName: userDisplayName ?? this.userDisplayName,
      userAka: userAka ?? this.userAka,
      userDisplayAs: userDisplayAs ?? this.userDisplayAs,
      status: status ?? this.status,
      edited: edited ?? this.edited,
      editedAt: editedAt ?? this.editedAt,
      spotName: spotName ?? this.spotName,
    );
  }
}
