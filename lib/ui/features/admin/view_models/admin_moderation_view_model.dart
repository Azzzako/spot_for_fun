import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:spot_for_fun/data/repositories/admin_moderation_repository.dart';
import 'package:spot_for_fun/data/repositories/auth_provider.dart';

enum ModerationAction { approve, reject }

@immutable
class ModerationState {
  const ModerationState({
    this.pendingIds = const {},
    this.errorMessage,
  });

  final Set<String> pendingIds;
  final String? errorMessage;

  ModerationState copyWith({
    Set<String>? pendingIds,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ModerationState(
      pendingIds: pendingIds ?? this.pendingIds,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  bool isBusy(String id) => pendingIds.contains(id);
}

class AdminModerationViewModel extends Notifier<ModerationState> {
  @override
  ModerationState build() => const ModerationState();

  void _run(String id, Future<void> Function() action) async {
    if (state.pendingIds.contains(id)) return;
    state = state.copyWith(
      pendingIds: {...state.pendingIds, id},
      clearError: true,
    );
    try {
      await action();
      state = state.copyWith(
        pendingIds: {...state.pendingIds}..remove(id),
      );
    } catch (e) {
      state = state.copyWith(
        pendingIds: {...state.pendingIds}..remove(id),
        errorMessage: 'No se pudo moderar el elemento. Inténtalo de nuevo.',
      );
    }
  }

  Future<void> moderateRating(String ratingId, ModerationAction action) async {
    final repo = ref.read(adminModerationRepositoryProvider);
    _run(ratingId, () async {
      if (action == ModerationAction.approve) {
        await repo.approveRating(ratingId);
      } else {
        await repo.rejectRating(ratingId);
      }
      ref.invalidate(pendingRatingsProvider);
    });
  }

  Future<void> moderatePhoto(String photoId, ModerationAction action) async {
    final repo = ref.read(adminModerationRepositoryProvider);
    _run(photoId, () async {
      if (action == ModerationAction.approve) {
        await repo.approvePhoto(photoId);
      } else {
        await repo.rejectPhoto(photoId);
      }
      ref.invalidate(pendingPhotosProvider);
    });
  }
}

final adminModerationViewModelProvider =
    NotifierProvider<AdminModerationViewModel, ModerationState>(
  AdminModerationViewModel.new,
);

/// Convenience boolean reflecting whether the signed-in user is allowed
/// inside the admin moderation flow. RLS still enforces on writes.
final isAdminModeratorProvider = Provider<bool>((ref) {
  return ref.watch(isAdminProvider);
});
