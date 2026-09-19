import 'package:spot_for_fun/data/models/spot_favorite_dto.dart';
import 'package:spot_for_fun/domain/models/spot_favorite.dart';

extension SpotFavoriteDtoMapper on SpotFavoriteDto {
  SpotFavorite toDomain() => SpotFavorite(
        spotId: spotId,
        userId: userId,
        createdAt: createdAt,
      );
}
