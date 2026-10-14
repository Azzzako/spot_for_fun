import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:spot_for_fun/domain/models/spot.dart';
import 'package:spot_for_fun/ui/features/spots/view_models/add_spot_photo_view_model.dart';
import 'package:spot_for_fun/ui/shared/widgets/photo_picker_grid.dart';
import 'package:spot_for_fun/ui/core/theme/app_colors.dart';
import 'package:spot_for_fun/ui/core/theme/app_theme.dart';

/// Bottom sheet that lets the spot author attach extra photos to a
/// spot directly (without a review). Photos enter pending and need
/// moderator approval.
class AddSpotPhotoSheet extends ConsumerStatefulWidget {
  const AddSpotPhotoSheet({super.key, required this.spot});

  final Spot spot;

  static Future<bool?> show(BuildContext context, Spot spot) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (_) => AddSpotPhotoSheet(spot: spot),
    );
  }

  @override
  ConsumerState<AddSpotPhotoSheet> createState() => _AddSpotPhotoSheetState();
}

class _AddSpotPhotoSheetState extends ConsumerState<AddSpotPhotoSheet> {
  Future<void> _submit() async {
    final result = await ref
        .read(addSpotPhotoViewModelProvider(widget.spot).notifier)
        .submit();
    if (!mounted) return;
    if (result.status == AddSpotPhotoStatus.success) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Fotos enviadas. Están en revisión.')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(addSpotPhotoViewModelProvider(widget.spot));
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
            Text('AGREGAR FOTOS', style: AppTheme.display(28)),
            const SizedBox(height: 4),
            Text(
              widget.spot.name.toUpperCase(),
              style: AppTheme.label(12, color: AppColors.boneMuted),
            ),
            const SizedBox(height: 8),
            Text(
              'Las fotos pasarán por revisión antes de mostrarse a la comunidad.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            PhotoPickerGrid(
              photos: state.newPhotos,
              maxPhotos: kSpotExtraMaxPhotos,
              onPhotosChanged: (p) => ref
                  .read(addSpotPhotoViewModelProvider(widget.spot).notifier)
                  .setPhotos(p),
            ),
            if (state.errorMessage != null &&
                state.status == AddSpotPhotoStatus.error)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(state.errorMessage!),
                ),
              ),
            const SizedBox(height: 20),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: !state.canSubmit ? null : _submit,
                child: state.isSaving
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: AppColors.asphalt,
                        ),
                      )
                    : const Text('ENVIAR FOTOS'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
