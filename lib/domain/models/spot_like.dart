import 'package:flutter/foundation.dart';

@immutable
class SpotLike {
  const SpotLike({
    required this.spotId,
    required this.userId,
    required this.createdAt,
  });

  final String spotId;
  final String userId;
  final DateTime createdAt;
}
