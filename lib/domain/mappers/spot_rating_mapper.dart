import 'package:spot_for_fun/data/models/spot_rating_dto.dart';
import 'package:spot_for_fun/domain/models/spot_rating.dart';

extension SpotRatingDtoMapper on SpotRatingDto {
  SpotRating toDomain() {
    return SpotRating(
      id: id,
      spotId: spotId,
      userId: userId,
      rating: rating,
      comment: comment,
      createdAt: createdAt,
      userDisplayName: userDisplayName,
      userAka: userAka,
      userAvatarUrl: userAvatarUrl,
      userDisplayAs: userDisplayAs,
      status: status,
      edited: edited,
      editedAt: editedAt,
      spotName: spotName,
    );
  }
}
