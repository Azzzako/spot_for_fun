import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:spot_for_fun/domain/enums.dart';
import 'package:spot_for_fun/domain/models/spot.dart';
import 'package:spot_for_fun/domain/models/spot_rating.dart';
import 'package:spot_for_fun/ui/features/spots/view_models/write_rating_view_model.dart';
import 'package:spot_for_fun/ui/shared/widgets/photo_picker_grid.dart';

/// Bottom sheet that creates or edits the current user's [SpotRating]
/// for the given [spot]. Validations: rating 1-5, comment 5-500 chars,
/// up to [kRatingMaxPhotos] photos (require moderation).
class WriteRatingSheet extends ConsumerStatefulWidget {
  const WriteRatingSheet({super.key, required this.spot});

  final Spot spot;

  static Future<bool?> show(BuildContext context, Spot spot) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (_) => WriteRatingSheet(spot: spot),
    );
  }

  @override
  ConsumerState<WriteRatingSheet> createState() => _WriteRatingSheetState();
}

class _WriteRatingSheetState extends ConsumerState<WriteRatingSheet> {
  late final TextEditingController _commentCtrl;

  @override
  void initState() {
    super.initState();
    _commentCtrl = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(writeRatingViewModelProvider(widget.spot).notifier).hydrate();
    });
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final result = await ref
        .read(writeRatingViewModelProvider(widget.spot).notifier)
        .submit();
    if (!mounted) return;
    if (result.status == WriteRatingStatus.success) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(
            result.isEditing
                ? 'Reseña actualizada. Vuelve a revisión.'
                : 'Reseña enviada. Está en revisión.',
          ),
        ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(writeRatingViewModelProvider(widget.spot));
    if (!state.hydrated) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: const SizedBox(
          height: 240,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_commentCtrl.text != state.comment) {
      _commentCtrl.text = state.comment;
      _commentCtrl.selection = TextSelection.collapsed(
        offset: state.comment.length,
      );
    }

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              state.isEditing ? 'Editar reseña' : 'Dejar reseña',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.spot.name,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
              ),
            ),
            const SizedBox(height: 20),
            if (state.isOwnSpot)
              _Banner(
                text: 'No puedes dejar reseña en tu propio spot.',
              )
            else if (state.hasExisting && !state.canEdit)
              _Banner(
                text:
                    'Esta reseña ya fue aprobada y no puede editarse de nuevo.',
              )
            else ...[
              Text('Tu calificación',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              _StarPicker(
                value: state.rating,
                onChanged: (v) => ref
                    .read(writeRatingViewModelProvider(widget.spot).notifier)
                    .setRating(v),
              ),
              const SizedBox(height: 18),
              Text('Comentario',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              TextField(
                controller: _commentCtrl,
                minLines: 3,
                maxLines: 6,
                maxLength: 500,
                enabled: state.canEdit,
                onChanged: (v) => ref
                    .read(writeRatingViewModelProvider(widget.spot).notifier)
                    .setComment(v),
                decoration: const InputDecoration(
                  hintText: 'Cuéntale a la comunidad qué te pareció…',
                ),
              ),
              if (state.hasExisting &&
                  (state.existing!.status == ReviewStatus.pending ||
                      state.existing!.status == ReviewStatus.rejected) &&
                  !state.existing!.edited)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Al guardar volverá a revisión. No podrás editarla de nuevo.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                    ),
                  ),
                ),
              const SizedBox(height: 18),
              Text(
                'Fotos (máx $kRatingMaxPhotos)',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              if (state.existingPhotos.isNotEmpty) ...[
                _ExistingPhotosGrid(
                  photos: state.existingPhotos,
                  onRemove: (id) {
                    ref
                        .read(writeRatingViewModelProvider(widget.spot).notifier)
                        .removeExistingPhoto(id);
                  },
                ),
                const SizedBox(height: 10),
              ],
              PhotoPickerGrid(
                photos: state.newPhotos,
                maxPhotos:
                    (kRatingMaxPhotos - state.existingPhotos.length)
                        .clamp(0, kRatingMaxPhotos),
                onPhotosChanged: (photos) => ref
                    .read(writeRatingViewModelProvider(widget.spot).notifier)
                    .setNewPhotos(photos),
              ),
              const SizedBox(height: 4),
              _ProximityHintInline(state: state),
            ],
            if (state.errorMessage != null &&
                state.status == WriteRatingStatus.error)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: _Banner(
                  text: state.errorMessage!,
                  error: true,
                ),
              ),
            const SizedBox(height: 20),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: (!state.canSubmit || state.isSaving)
                    ? null
                    : _submit,
                child: state.isSaving
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                    : Text(state.isEditing ? 'Guardar cambios' : 'Enviar reseña'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StarPicker extends StatelessWidget {
  const _StarPicker({required this.value, required this.onChanged});
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: List.generate(5, (i) {
        final star = i + 1;
        final filled = star <= value;
        return Padding(
          padding: const EdgeInsets.only(right: 6),
          child: InkResponse(
            onTap: () => onChanged(star),
            radius: 28,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                filled ? Icons.star_rounded : Icons.star_border_rounded,
                size: 40,
                color: filled
                    ? const Color(0xFFFBBF24)
                    : theme.colorScheme.onSurface.withValues(alpha: 0.35),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.text, this.error = false});
  final String text;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: error
            ? theme.colorScheme.errorContainer
            : theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text),
    );
  }
}

class _ProximityHintInline extends StatelessWidget {
  const _ProximityHintInline({required this.state});
  final WriteRatingState state;

  @override
  Widget build(BuildContext context) {
    if (state.isOwnSpot) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final d = state.distanceMeters;

    String text;
    Color color;
    switch (state.locationStatus) {
      case RatingLocationStatus.denied:
        text = 'Activa el permiso de ubicación para dejar una reseña.';
        color = theme.colorScheme.error;
      case RatingLocationStatus.serviceOff:
        text = 'Enciende tu GPS para dejar una reseña.';
        color = theme.colorScheme.error;
      case RatingLocationStatus.error:
        text = 'No pudimos obtener tu ubicación. Inténtalo más tarde.';
        color = theme.colorScheme.error;
      case RatingLocationStatus.unknown:
        return const SizedBox.shrink();
      case RatingLocationStatus.granted:
        if (d == null) return const SizedBox.shrink();
        if (state.isNearEnough) {
          text = 'Estás a ${d.round()} m del spot · listo para reseñar.';
          color = theme.colorScheme.primary;
        } else {
          text =
              'Estás a ${d.round()} m. Acércate a menos de ${kRatingMaxDistanceMeters.toInt()} m para dejar reseña.';
          color = theme.colorScheme.onSurface.withValues(alpha: 0.7);
        }
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(text, style: theme.textTheme.bodySmall?.copyWith(color: color)),
    );
  }
}

class _ExistingPhotosGrid extends StatelessWidget {
  const _ExistingPhotosGrid({
    required this.photos,
    required this.onRemove,
  });

  final List<SpotPhoto> photos;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: photos.length,
      itemBuilder: (ctx, i) {
        final photo = photos[i];
        final pending = photo.photoStatus == PhotoStatus.pending;
        return Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: photo.url,
                fit: BoxFit.cover,
                placeholder: (_, _) => Container(
                  color: theme.colorScheme.surfaceContainerHigh,
                ),
                errorWidget: (_, _, _) => Container(
                  color: theme.colorScheme.surfaceContainerHigh,
                  child: const Icon(Icons.broken_image),
                ),
              ),
            ),
            if (pending)
              Positioned(
                left: 4,
                bottom: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'En revisión',
                    style: TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ),
            Positioned(
              top: 4,
              right: 4,
              child: Material(
                color: Colors.black54,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => onRemove(photo.id),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.close, size: 16, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
