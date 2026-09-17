import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:spot_for_fun/data/repositories/auth_provider.dart';
import 'package:spot_for_fun/data/repositories/spot_repository.dart';
import 'package:spot_for_fun/domain/models/spot.dart';
import 'package:spot_for_fun/ui/shared/widgets/photo_picker_grid.dart';

enum AddSpotPhotoStatus { idle, saving, success, error }

const int kSpotExtraMaxPhotos = 5;

@immutable
class AddSpotPhotoState {
  const AddSpotPhotoState({
    this.newPhotos = const [],
    this.status = AddSpotPhotoStatus.idle,
    this.errorMessage,
  });

  final List<PhotoItem> newPhotos;
  final AddSpotPhotoStatus status;
  final String? errorMessage;

  bool get isSaving => status == AddSpotPhotoStatus.saving;
  bool get canSubmit => newPhotos.isNotEmpty && !isSaving;

  AddSpotPhotoState copyWith({
    List<PhotoItem>? newPhotos,
    AddSpotPhotoStatus? status,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AddSpotPhotoState(
      newPhotos: newPhotos ?? this.newPhotos,
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class AddSpotPhotoViewModel
    extends AutoDisposeFamilyNotifier<AddSpotPhotoState, Spot> {
  late final Spot spot;

  @override
  AddSpotPhotoState build(Spot arg) {
    spot = arg;
    return const AddSpotPhotoState();
  }

  void setPhotos(List<PhotoItem> photos) =>
      state = state.copyWith(newPhotos: photos, clearError: true);

  Future<AddSpotPhotoState> submit() async {
    if (state.newPhotos.isEmpty) return state;
    state = state.copyWith(status: AddSpotPhotoStatus.saving, clearError: true);

    final uid = ref.read(currentUserIdProvider);
    if (uid == null) {
      state = state.copyWith(
        status: AddSpotPhotoStatus.error,
        errorMessage: 'Sesión expirada.',
      );
      return state;
    }

    try {
      final repo = ref.read(spotRepositoryProvider);
      for (var i = 0; i < state.newPhotos.length; i++) {
        final photo = state.newPhotos[i];
        if (photo.source != PhotoSource.file) continue;
        await repo.submitPendingPhoto(
          userId: uid,
          spotId: spot.id,
          bytes: photo.bytes!,
          ext: photo.ext,
          position: i,
        );
      }
      state = state.copyWith(
        status: AddSpotPhotoStatus.success,
        newPhotos: const [],
      );
      return state;
    } catch (e) {
      state = state.copyWith(
        status: AddSpotPhotoStatus.error,
        errorMessage: e.toString(),
      );
      return state;
    }
  }
}

final addSpotPhotoViewModelProvider = NotifierProvider.autoDispose
    .family<AddSpotPhotoViewModel, AddSpotPhotoState, Spot>(
        AddSpotPhotoViewModel.new);
