import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import 'package:spot_for_fun/data/repositories/auth_provider.dart';
import 'package:spot_for_fun/data/repositories/spot_rating_repository.dart';
import 'package:spot_for_fun/data/repositories/spot_repository.dart';
import 'package:spot_for_fun/domain/enums.dart';
import 'package:spot_for_fun/domain/models/spot.dart';
import 'package:spot_for_fun/domain/models/spot_rating.dart';
import 'package:spot_for_fun/ui/shared/utils/location_helper.dart';
import 'package:spot_for_fun/ui/shared/widgets/photo_picker_grid.dart';

enum WriteRatingStatus { idle, loading, saving, success, error }

enum RatingLocationStatus {
  unknown,
  granted,
  denied,
  serviceOff,
  error,
}

const double kRatingMaxDistanceMeters = 500;
const int kRatingMaxPhotos = 2;

@immutable
class WriteRatingState {
  const WriteRatingState({
    this.rating = 0,
    this.comment = '',
    this.originalRating = 0,
    this.originalComment = '',
    this.existing,
    this.existingPhotos = const [],
    this.newPhotos = const [],
    this.removedExistingIds = const [],
    this.hydrated = false,
    this.status = WriteRatingStatus.idle,
    this.errorMessage,
    this.isOwnSpot = false,
    this.locationStatus = RatingLocationStatus.unknown,
    this.distanceMeters,
  });

  final int rating;
  final String comment;
  final int originalRating;
  final String originalComment;
  final SpotRating? existing;
  final List<SpotPhoto> existingPhotos;
  final List<PhotoItem> newPhotos;
  final List<String> removedExistingIds;
  final bool hydrated;
  final WriteRatingStatus status;
  final String? errorMessage;
  final bool isOwnSpot;
  final RatingLocationStatus locationStatus;
  final double? distanceMeters;

  bool get hasExisting => existing != null;
  bool get isEditing => hasExisting;

  bool get canEdit {
    final e = existing;
    if (e == null) return true;
    if (e.edited) return false;
    return e.status == ReviewStatus.pending ||
        e.status == ReviewStatus.rejected;
  }

  bool get isSaving => status == WriteRatingStatus.saving;

  bool get hasChanges =>
      rating != originalRating ||
      comment.trim() != originalComment.trim() ||
      newPhotos.isNotEmpty ||
      removedExistingIds.isNotEmpty;

  /// True when the user has a known location and is within range of the
  /// spot. False otherwise (no permission, no fix, or too far).
  bool get isNearEnough {
    final d = distanceMeters;
    if (d == null) return false;
    return d <= kRatingMaxDistanceMeters;
  }

  /// True when the form can be submitted, considering review state,
  /// location, and change detection.
  bool get canSubmit {
    if (!canEdit) return false;
    if (!hasChanges) return false;
    if (locationStatus != RatingLocationStatus.granted) return false;
    return isNearEnough;
  }

  /// Total photos the user is keeping (existing + new), used to
  /// enforce the 2-photo limit per review.
  int get totalPhotos => existingPhotos.length + newPhotos.length;

  WriteRatingState copyWith({
    int? rating,
    String? comment,
    int? originalRating,
    String? originalComment,
    SpotRating? existing,
    List<SpotPhoto>? existingPhotos,
    List<PhotoItem>? newPhotos,
    List<String>? removedExistingIds,
    bool? hydrated,
    WriteRatingStatus? status,
    String? errorMessage,
    bool? isOwnSpot,
    RatingLocationStatus? locationStatus,
    double? distanceMeters,
    bool clearError = false,
    bool clearExisting = false,
    bool clearDistance = false,
  }) {
    return WriteRatingState(
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      originalRating: originalRating ?? this.originalRating,
      originalComment: originalComment ?? this.originalComment,
      existing: clearExisting ? null : (existing ?? this.existing),
      existingPhotos: existingPhotos ?? this.existingPhotos,
      newPhotos: newPhotos ?? this.newPhotos,
      removedExistingIds: removedExistingIds ?? this.removedExistingIds,
      hydrated: hydrated ?? this.hydrated,
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isOwnSpot: isOwnSpot ?? this.isOwnSpot,
      locationStatus: locationStatus ?? this.locationStatus,
      distanceMeters:
          clearDistance ? null : (distanceMeters ?? this.distanceMeters),
    );
  }
}

class WriteRatingViewModel
    extends AutoDisposeFamilyNotifier<WriteRatingState, Spot> {
  late final Spot spot;

  @override
  WriteRatingState build(Spot arg) {
    spot = arg;
    return const WriteRatingState();
  }

  Future<void> hydrate() async {
    if (state.hydrated) return;
    final uid = ref.read(currentUserIdProvider);
    final isOwnSpot = uid != null && uid == spot.authorId;

    final mine = isOwnSpot
        ? null
        : await _safe(() async {
            final repo = ref.read(spotRatingRepositoryProvider);
            return repo.fetchMine(spot.id);
          });

    List<SpotPhoto> existingPhotos = const [];
    if (mine != null) {
      try {
        final spotRepo = ref.read(spotRepositoryProvider);
        existingPhotos = await spotRepo.fetchPhotosForReview(mine.id);
      } catch (_) {
        existingPhotos = const [];
      }
    }

    final location = await _resolveLocation();

    state = state.copyWith(
      hydrated: true,
      isOwnSpot: isOwnSpot,
      existing: mine,
      rating: mine?.rating ?? state.rating,
      comment: mine?.comment ?? state.comment,
      originalRating: mine?.rating ?? 0,
      originalComment: mine?.comment ?? '',
      existingPhotos: existingPhotos,
      locationStatus: location.$1,
      distanceMeters: location.$2,
      clearDistance: location.$2 == null,
    );
  }

  Future<SpotRating?> _safe(Future<SpotRating?> Function() fn) async {
    try {
      return await fn();
    } catch (_) {
      return null;
    }
  }

  Future<(RatingLocationStatus, double?)> _resolveLocation() async {
    final perm = await LocationHelper.ensurePermission();
    switch (perm) {
      case LocationStatus.denied:
        return (RatingLocationStatus.denied, null);
      case LocationStatus.deniedForever:
        return (RatingLocationStatus.denied, null);
      case LocationStatus.serviceOff:
        return (RatingLocationStatus.serviceOff, null);
      case LocationStatus.error:
        return (RatingLocationStatus.error, null);
      case LocationStatus.granted:
        final pos = await LocationHelper.currentPosition();
        if (pos == null) return (RatingLocationStatus.error, null);
        final user = LatLng(pos.latitude, pos.longitude);
        final spotLatLng = LatLng(spot.lat, spot.lng);
        final meters = const Distance()
            .as(LengthUnit.Meter, spotLatLng, user);
        return (RatingLocationStatus.granted, meters);
    }
  }

  void setRating(int v) =>
      state = state.copyWith(rating: v, clearError: true);
  void setComment(String v) =>
      state = state.copyWith(comment: v, clearError: true);
  void setNewPhotos(List<PhotoItem> v) =>
      state = state.copyWith(newPhotos: v, clearError: true);

  void removeExistingPhoto(String photoId) {
    state = state.copyWith(
      removedExistingIds: [...state.removedExistingIds, photoId],
      existingPhotos: state.existingPhotos
          .where((p) => p.id != photoId)
          .toList(growable: false),
    );
  }

  void undoRemoveExistingPhoto(SpotPhoto photo) {
    state = state.copyWith(
      removedExistingIds:
          state.removedExistingIds.where((id) => id != photo.id).toList(),
      existingPhotos: [...state.existingPhotos, photo],
    );
  }

  String? _validate() {
    if (state.rating < 1 || state.rating > 5) {
      return 'Selecciona una calificación de 1 a 5 estrellas';
    }
    final t = state.comment.trim();
    if (t.length < 5) return 'El comentario necesita al menos 5 caracteres';
    if (t.length > 500) return 'Máximo 500 caracteres';
    if (state.totalPhotos > kRatingMaxPhotos) {
      return 'Máximo $kRatingMaxPhotos fotos por reseña';
    }
    return null;
  }

  Future<WriteRatingState> submit() async {
    final err = _validate();
    if (err != null) {
      state = state.copyWith(
        status: WriteRatingStatus.error,
        errorMessage: err,
      );
      return state;
    }
    if (!state.hasChanges) return state;
    if (state.hasExisting && !state.canEdit) {
      state = state.copyWith(
        status: WriteRatingStatus.error,
        errorMessage: 'Esta reseña ya no se puede editar.',
      );
      return state;
    }
    if (state.locationStatus != RatingLocationStatus.granted ||
        !state.isNearEnough) {
      state = state.copyWith(
        status: WriteRatingStatus.error,
        errorMessage:
            'Necesitas estar a ${kRatingMaxDistanceMeters.toInt()} m o menos del spot para dejar una reseña.',
      );
      return state;
    }

    state = state.copyWith(
      status: WriteRatingStatus.saving,
      clearError: true,
    );

    final uid = ref.read(currentUserIdProvider);
    if (uid == null) {
      state = state.copyWith(
        status: WriteRatingStatus.error,
        errorMessage: 'Sesión expirada.',
      );
      return state;
    }

    final spotRepo = ref.read(spotRepositoryProvider);
    final ratingRepo = ref.read(spotRatingRepositoryProvider);

    try {
      // 1. Delete removed existing photos (RLS: only pending, only own).
      for (final id in state.removedExistingIds) {
        try {
          await spotRepo.deleteSpotPhoto(id);
        } catch (_) {
          // best-effort: a photo may already be approved, ignore
        }
      }

      // 2. Create or update the rating.
      final SpotRating result;
      if (state.existing != null) {
        result = await ratingRepo.update(
          id: state.existing!.id,
          rating: state.rating,
          comment: state.comment.trim(),
        );
      } else {
        result = await ratingRepo.create(
          spotId: spot.id,
          userId: uid,
          rating: state.rating,
          comment: state.comment.trim(),
        );
      }

      // 3. Upload new photos tied to the resulting review id.
      final photos = state.newPhotos;
      for (var i = 0; i < photos.length; i++) {
        final photo = photos[i];
        if (photo.source != PhotoSource.file) continue;
        await spotRepo.submitPendingPhoto(
          userId: uid,
          spotId: spot.id,
          bytes: photo.bytes!,
          ext: photo.ext,
          reviewId: result.id,
          position: i,
        );
      }

      state = state.copyWith(
        existing: result,
        originalRating: result.rating,
        originalComment: result.comment ?? '',
        newPhotos: const [],
        removedExistingIds: const [],
        status: WriteRatingStatus.success,
      );
      return state;
    } catch (e) {
      state = state.copyWith(
        status: WriteRatingStatus.error,
        errorMessage: _mapError(e.toString()),
      );
      return state;
    }
  }

  String _mapError(String msg) {
    final lower = msg.toLowerCase();
    if (lower.contains('check constraint') && lower.contains('rating')) {
      return 'Calificación inválida.';
    }
    if (lower.contains('row-level security') ||
        lower.contains('policy') ||
        lower.contains('violates')) {
      return 'No se pudo guardar la reseña (permisos o reglas).';
    }
    return msg;
  }
}

final writeRatingViewModelProvider = NotifierProvider.autoDispose
    .family<WriteRatingViewModel, WriteRatingState, Spot>(
        WriteRatingViewModel.new);
