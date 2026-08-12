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
    this.difficulty = SpotDifficulty.beginner,
    this.bestTime = const {},
    this.markerKind,
    this.photos = const [],
    this.submitState = SubmitState.idle,
    this.uploadedCount = 0,
    this.errorMessage,
  });

  final LatLng? pickedLocation;
  final bool locating;
  final SpotType type;
  final SpotDifficulty difficulty;
  final Set<BestTimeSlot> bestTime;
  final MarkerKind? markerKind;
  final List<PhotoItem> photos;
  final SubmitState submitState;
  final int uploadedCount;
  final String? errorMessage;

  int get filePhotoCount =>
      photos.where((p) => p.source == PhotoSource.file).length;

  CreateSpotState copyWith({
    LatLng? pickedLocation,
    bool? locating,
    SpotType? type,
    SpotDifficulty? difficulty,
    Set<BestTimeSlot>? bestTime,
    MarkerKind? markerKind,
    List<PhotoItem>? photos,
    SubmitState? submitState,
    int? uploadedCount,
    String? errorMessage,
    bool clearErrorMessage = false,
    bool clearMarkerKind = false,
    bool clearPickedLocation = false,
  }) {
    return CreateSpotState(
      pickedLocation: clearPickedLocation
          ? null
          : (pickedLocation ?? this.pickedLocation),
      locating: locating ?? this.locating,
      type: type ?? this.type,
      difficulty: difficulty ?? this.difficulty,
      bestTime: bestTime ?? this.bestTime,
      markerKind: clearMarkerKind ? null : (markerKind ?? this.markerKind),
      photos: photos ?? this.photos,
      submitState: submitState ?? this.submitState,
      uploadedCount: uploadedCount ?? this.uploadedCount,
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
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

  void toggleBestTime(BestTimeSlot slot) {
    final next = <BestTimeSlot>{...state.bestTime};
    if (next.contains(slot)) {
      next.remove(slot);
    } else {
      next.add(slot);
    }
    state = state.copyWith(bestTime: next);
  }

  void setMarkerKind(MarkerKind? kind) {
    state = state.copyWith(
      markerKind: kind,
      clearMarkerKind: kind == null,
    );
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

  Future<void> submit({
    required String name,
    required String description,
    String? safetyNotes,
  }) async {
    if (state.bestTime.isEmpty) {
      state = state.copyWith(
        submitState: SubmitState.error,
        errorMessage: 'Selecciona al menos un mejor horario',
      );
      return;
    }
    final loc = state.pickedLocation;
    if (loc == null) {
      state = state.copyWith(
        submitState: SubmitState.error,
        errorMessage: 'Selecciona una ubicacion en el mapa',
      );
      return;
    }

    state = state.copyWith(
      submitState: SubmitState.uploading,
      uploadedCount: 0,
      clearErrorMessage: true,
    );

    final userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      state = state.copyWith(
        submitState: SubmitState.error,
        errorMessage: 'Sesion expirada. Vuelve a iniciar sesion.',
      );
      return;
    }
    final repo = ref.read(spotRepositoryProvider);

    try {
      final spot = await repo.createSpot(
        authorId: userId,
        name: name,
        description: description,
        lat: loc.latitude,
        lng: loc.longitude,
        type: state.type,
        difficulty: state.difficulty,
        bestTime: state.bestTime.toList(),
        safetyNotes: safetyNotes,
      );

      final photoErrors = <String>[];
      for (var i = 0; i < state.photos.length; i++) {
        final photo = state.photos[i];
        if (photo.source != PhotoSource.file) continue;
        try {
          final url = await repo.uploadSpotPhoto(
            userId: userId,
            spotId: spot.id,
            bytes: photo.bytes!,
            ext: photo.ext,
          );
          await repo.attachSpotPhoto(
            spotId: spot.id,
            url: url,
            position: i,
          );
          state = state.copyWith(uploadedCount: i + 1);
        } catch (e) {
          photoErrors.add('Foto ${i + 1}: $e');
        }
      }

      if (photoErrors.isNotEmpty) {
        state = state.copyWith(
          submitState: SubmitState.partialSuccess,
          errorMessage: photoErrors.join('\n'),
        );
        return;
      }

      state = state.copyWith(submitState: SubmitState.success);
    } catch (e) {
      state = state.copyWith(
        submitState: SubmitState.error,
        errorMessage: e.toString(),
      );
    }
  }
}

final createSpotViewModelProvider =
    NotifierProvider.autoDispose<CreateSpotViewModel, CreateSpotState>(
        CreateSpotViewModel.new);
