import 'package:flutter/foundation.dart';

@immutable
class SpotFavorite {
  const SpotFavorite({
    required this.spotId,
    required this.userId,
    required this.createdAt,
  });

  final String spotId;
  final String userId;
  final DateTime createdAt;
}
