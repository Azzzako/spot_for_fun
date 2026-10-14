import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:spot_for_fun/data/repositories/social_repository.dart';
import 'package:spot_for_fun/data/repositories/spot_repository.dart';

/// Favorite toggle. Returns `false` when the request failed so the
/// caller can tell the user; taps that arrive while the same toggle is
/// still in flight are ignored.
class SocialViewModel extends Notifier<void> {
  final _inFlight = <String>{};

  @override
  void build() {}

  Future<bool> toggleFavorite({
    required String spotId,
    required bool currentlyFavorited,
  }) {
    final repo = ref.read(socialRepositoryProvider);
    return _run(
      spotId,
      () => currentlyFavorited
          ? repo.unfavorite(spotId)
          : repo.favorite(spotId),
    );
  }

  Future<bool> _run(String key, Future<void> Function() action) async {
    if (!_inFlight.add(key)) return true;
    try {
      await action();
      _invalidateSpotLists();
      return true;
    } catch (_) {
      return false;
    } finally {
      _inFlight.remove(key);
    }
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
