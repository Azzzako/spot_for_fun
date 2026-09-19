import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:spot_for_fun/data/repositories/social_repository.dart';
import 'package:spot_for_fun/data/repositories/spot_repository.dart';

class SocialViewModel extends Notifier<void> {
  @override
  void build() {}

  Future<void> toggleLike({
    required String spotId,
    required bool currentlyLiked,
  }) async {
    final repo = ref.read(socialRepositoryProvider);
    if (currentlyLiked) {
      await repo.unlike(spotId);
    } else {
      await repo.like(spotId);
    }
    _invalidateSpotLists();
  }

  Future<void> toggleFavorite({
    required String spotId,
    required bool currentlyFavorited,
  }) async {
    final repo = ref.read(socialRepositoryProvider);
    if (currentlyFavorited) {
      await repo.unfavorite(spotId);
    } else {
      await repo.favorite(spotId);
    }
    _invalidateSpotLists();
  }

  void _invalidateSpotLists() {
    ref.invalidate(myLikedSpotIdsProvider);
    ref.invalidate(myFavoritedSpotIdsProvider);
    ref.invalidate(approvedSpotsProvider);
    ref.invalidate(mySpotsProvider);
    ref.invalidate(myFavoriteSpotsProvider);
  }
}

final socialViewModelProvider =
    NotifierProvider<SocialViewModel, void>(SocialViewModel.new);
