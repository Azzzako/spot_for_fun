import 'package:spot_for_fun/data/models/spot_like_dto.dart';
import 'package:spot_for_fun/domain/models/spot_like.dart';

extension SpotLikeDtoMapper on SpotLikeDto {
  SpotLike toDomain() => SpotLike(
        spotId: spotId,
        userId: userId,
        createdAt: createdAt,
      );
}
