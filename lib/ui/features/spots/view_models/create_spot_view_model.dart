import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import 'package:spot_for_fun/data/repositories/auth_provider.dart';
import 'package:spot_for_fun/data/repositories/spot_repository.dart';
import 'package:spot_for_fun/domain/enums.dart';
import 'package:spot_for_fun/ui/shared/utils/location_helper.dart';
import 'package:spot_for_fun/ui/shared/widgets/photo_picker_grid.dart';

enum SubmitState { idle, uploading, partialSuccess, success, error }

@immutable
class CreateSpotState {
  const CreateSpotState({
    this.pickedLocation,
    this.locating = false,
    this.type = SpotType.street,
    this.difficulty,
    this.bestTime = const {},
    this.photos = const [],
    this.submitState = SubmitState.idle,
    this.uploadedCount = 0,
    this.errorMessage,
    this.createdSpotId,
    this.uploadedPhotoIndexes = const {},
  });

  final LatLng? pickedLocation;
  final bool locating;
  final SpotType type;
  final SpotDifficulty? difficulty;
  final Set<BestTimeSlot> bestTime;
  final List<PhotoItem> photos;
  final SubmitState submitState;
  final int uploadedCount;
  final String? errorMessage;

  /// Set once the spot row exists. A retry after a photo failure only
  /// uploads the missing photos instead of creating another spot.
  final String? createdSpotId;

  /// Indexes in [photos] already uploaded and attached to the spot.
  final Set<int> uploadedPhotoIndexes;

  /// The spot exists but some photos are missing; the form is frozen.
  bool get isSpotCreated => createdSpotId != null;

  int get filePhotoCount =>
      photos.where((p) => p.source == PhotoSource.file).length;

  CreateSpotState copyWith({
    LatLng? pickedLocation,
    bool? locating,
    SpotType? type,
    SpotDifficulty? difficulty,
    Set<BestTimeSlot>? bestTime,
    List<PhotoItem>? photos,
    SubmitState? submitState,
    int? uploadedCount,
    String? errorMessage,
    String? createdSpotId,
    Set<int>? uploadedPhotoIndexes,
    bool clearErrorMessage = false,
    bool clearDifficulty = false,
    bool clearPickedLocation = false,
  }) {
    return CreateSpotState(
      pickedLocation: clearPickedLocation
          ? null
          : (pickedLocation ?? this.pickedLocation),
      locating: locating ?? this.locating,
      type: type ?? this.type,
      difficulty: clearDifficulty ? null : (difficulty ?? this.difficulty),
      bestTime: bestTime ?? this.bestTime,
      photos: photos ?? this.photos,
      submitState: submitState ?? this.submitState,
      uploadedCount: uploadedCount ?? this.uploadedCount,
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
      createdSpotId: createdSpotId ?? this.createdSpotId,
      uploadedPhotoIndexes: uploadedPhotoIndexes ?? this.uploadedPhotoIndexes,
    );
  }
}

class CreateSpotViewModel extends AutoDisposeNotifier<CreateSpotState> {
  @override
  CreateSpotState build() => const CreateSpotState();

  Future<LatLng?> initLocation() async {
    state = state.copyWith(locating: true);
    final status = await LocationHelper.ensurePermission();
    if (status == LocationStatus.granted) {
      final pos = await LocationHelper.currentPosition();
      state = state.copyWith(locating: false);
      if (pos != null) {
        final loc = LatLng(pos.latitude, pos.longitude);
        state = state.copyWith(pickedLocation: loc);
        return loc;
      }
    }
    state = state.copyWith(locating: false);
    return null;
  }

  Future<LatLng?> relocateFromGps() async {
    state = state.copyWith(locating: true);
    final pos = await LocationHelper.currentPosition();
    state = state.copyWith(locating: false);
    if (pos != null) {
      final loc = LatLng(pos.latitude, pos.longitude);
      state = state.copyWith(pickedLocation: loc);
      return loc;
    }
    return null;
  }

  void setPickedLocation(LatLng loc) {
    state = state.copyWith(pickedLocation: loc);
  }

  void setType(SpotType type) {
    state = state.copyWith(type: type);
  }

  void setDifficulty(SpotDifficulty d) {
    state = state.copyWith(difficulty: d);
  }

  void clearDifficulty() {
    state = state.copyWith(clearDifficulty: true);
  }

  void toggleBestTime(BestTimeSlot slot) {
    final next = <BestTimeSlot>{...state.bestTime};
    if (next.contains(slot)) {
      next.remove(slot);
    } else {
      next.add(slot);
    }
    state = state.copyWith(bestTime: next);
  }

  void setPhotos(List<PhotoItem> photos) {
    state = state.copyWith(photos: photos);
  }

  void resetSubmit() {
    state = state.copyWith(
      submitState: SubmitState.idle,
      uploadedCount: 0,
      clearErrorMessage: true,
    );
  }

  /// Creates the spot (first call only) and uploads every photo that
  /// isn't attached yet. Safe to call again after [SubmitState.partialSuccess].
  Future<void> submit({
    required String name,
    required String description,
    String? safetyNotes,
  }) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      state = state.copyWith(
        submitState: SubmitState.error,
        errorMessage: 'Sesion expirada. Vuelve a iniciar sesion.',
      );
      return;
    }

    final spotId = state.createdSpotId ??
        await _createSpot(
          userId: userId,
          name: name,
          description: description,
          safetyNotes: safetyNotes,
        );
    if (spotId == null) return;

    await _uploadMissingPhotos(userId: userId, spotId: spotId);
  }

  Future<String?> _createSpot({
    required String userId,
    required String name,
    required String description,
    String? safetyNotes,
  }) async {
    String? invalid;
    if (state.bestTime.isEmpty) {
      invalid = 'Selecciona al menos un mejor horario';
    } else if (state.difficulty == null) {
      invalid = 'Selecciona una dificultad';
    } else if (state.photos.isEmpty) {
      invalid = 'Agrega al menos 1 foto';
    } else if (state.pickedLocation == null) {
      invalid = 'Selecciona una ubicacion en el mapa';
    }
    if (invalid != null) {
      state = state.copyWith(
        submitState: SubmitState.error,
        errorMessage: invalid,
      );
      return null;
    }

    state = state.copyWith(
      submitState: SubmitState.uploading,
      uploadedCount: 0,
      clearErrorMessage: true,
    );

    try {
      final loc = state.pickedLocation!;
      final spot = await ref.read(spotRepositoryProvider).createSpot(
            authorId: userId,
            name: name,
            description: description,
            lat: loc.latitude,
            lng: loc.longitude,
            type: state.type,
            difficulty: state.difficulty!,
            bestTime: state.bestTime.toList(),
            safetyNotes: safetyNotes,
          );
      state = state.copyWith(createdSpotId: spot.id);
      return spot.id;
    } catch (e) {
      debugPrint('createSpot failed: $e');
      state = state.copyWith(
        submitState: SubmitState.error,
        errorMessage:
            'No se pudo publicar el spot. Revisa tu conexión e inténtalo de nuevo.',
      );
      return null;
    }
  }

  Future<void> _uploadMissingPhotos({
    required String userId,
    required String spotId,
  }) async {
    final repo = ref.read(spotRepositoryProvider);
    final uploaded = <int>{...state.uploadedPhotoIndexes};
    state = state.copyWith(
      submitState: SubmitState.uploading,
      uploadedCount: uploaded.length,
      clearErrorMessage: true,
    );

    final failed = <int>[];
    for (var i = 0; i < state.photos.length; i++) {
      final photo = state.photos[i];
      if (photo.source != PhotoSource.file || uploaded.contains(i)) continue;
      try {
        final url = await repo.uploadSpotPhoto(
          userId: userId,
          spotId: spotId,
          bytes: photo.bytes!,
          ext: photo.ext,
        );
        await repo.attachSpotPhoto(
          userId: userId,
          spotId: spotId,
          url: url,
          position: i,
        );
        uploaded.add(i);
        state = state.copyWith(
          uploadedCount: uploaded.length,
          uploadedPhotoIndexes: {...uploaded},
        );
      } catch (e) {
        debugPrint('photo ${i + 1} upload failed: $e');
        failed.add(i + 1);
      }
    }

    // The profile tab stays mounted in the shell, so its cached list
    // must be told about the new spot (with whatever photos made it).
    ref.invalidate(mySpotsProvider);

    if (failed.isEmpty) {
      state = state.copyWith(submitState: SubmitState.success);
      return;
    }

    final which = failed.length == 1
        ? 'la foto ${failed.single}'
        : 'las fotos ${failed.take(failed.length - 1).join(', ')} y ${failed.last}';
    state = state.copyWith(
      submitState: SubmitState.partialSuccess,
      errorMessage: 'Tu spot ya se creó, pero no se pudo subir $which. '
          'Revisa tu conexión y reintenta.',
    );
  }
}

final createSpotViewModelProvider =
    NotifierProvider.autoDispose<CreateSpotViewModel, CreateSpotState>(
        CreateSpotViewModel.new);
