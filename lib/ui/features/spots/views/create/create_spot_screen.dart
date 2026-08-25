import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import 'package:spot_for_fun/ui/core/router/app_router.dart';
import 'package:spot_for_fun/ui/core/theme/app_colors.dart';
import 'package:spot_for_fun/domain/enums.dart';
import 'package:spot_for_fun/ui/shared/widgets/photo_picker_grid.dart';
import 'package:spot_for_fun/ui/features/spots/view_models/create_spot_view_model.dart';

class CreateSpotScreen extends ConsumerStatefulWidget {
  const CreateSpotScreen({super.key});

  @override
  ConsumerState<CreateSpotScreen> createState() => _CreateSpotScreenState();
}

class _CreateSpotScreenState extends ConsumerState<CreateSpotScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _safetyCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _safetyCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final vm = ref.read(createSpotViewModelProvider.notifier);
    final previous = ref.read(createSpotViewModelProvider).submitState;
    await vm.submit(
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      safetyNotes: _safetyCtrl.text.trim().isEmpty
          ? null
          : _safetyCtrl.text.trim(),
    );
    if (!mounted) return;
    final after = ref.read(createSpotViewModelProvider).submitState;
    if (after == SubmitState.success && previous != SubmitState.success) {
      _snack('Tu spot esta en revision');
      context.go(AppRoutes.mySpots);
    } else if (after == SubmitState.error &&
        ref.read(createSpotViewModelProvider).errorMessage != null) {
      _snack(ref.read(createSpotViewModelProvider).errorMessage!);
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createSpotViewModelProvider);
    final vm = ref.read(createSpotViewModelProvider.notifier);
    final theme = Theme.of(context);
    final busy = state.submitState == SubmitState.uploading;

    return Scaffold(
      backgroundColor: theme.brightness == Brightness.dark
          ? theme.colorScheme.surface
          : AppColors.brandCream,
      appBar: AppBar(
        backgroundColor: theme.brightness == Brightness.dark
            ? theme.colorScheme.surface
            : AppColors.brandCream,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Agrega un nuevo spot',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              _PhotosCard(
                photos: state.photos,
                onPhotosChanged: vm.setPhotos,
              ),
              const SizedBox(height: 24),
              _SectionLabel('Nombre del spot'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameCtrl,
                decoration: _inputDecoration(
                  hint: 'Ej. Escaleras del Parque',
                ),
                maxLength: 80,
                textInputAction: TextInputAction.next,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Requerido';
                  if (v.trim().length < 3) return 'Minimo 3 caracteres';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _SectionLabel('Ubicacion'),
              const SizedBox(height: 8),
              _LocationField(
                location: state.pickedLocation,
                onTap: () async {
                  await context.push(AppRoutes.spotPickLocation);
                },
              ),
              const SizedBox(height: 16),
              _SectionLabel('Tipo de spot'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: SpotType.values.map((t) {
                  final selected = state.type == t;
                  return _TypeChip(
                    label: t.label,
                    selected: selected,
                    onTap: () => vm.setType(t),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              _SectionLabel('Descripcion'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descCtrl,
                decoration: _inputDecoration(
                  hint: 'Cuentanos algo sobre el spot...',
                ),
                maxLines: 4,
                maxLength: 500,
              ),
              const SizedBox(height: 8),
              _MoreDetailsTile(
                state: state,
                vm: vm,
                safetyCtrl: _safetyCtrl,
              ),
              if (state.submitState == SubmitState.partialSuccess)
                _Banner(
                  icon: Icons.warning_amber_rounded,
                  text:
                      'Spot creado, pero algunas fotos fallaron:\n${state.errorMessage ?? ''}',
                ),
              if (state.submitState == SubmitState.error &&
                  state.errorMessage != null)
                _Banner(
                  icon: Icons.error_outline,
                  text: state.errorMessage!,
                  error: true,
                ),
              const SizedBox(height: 24),
              if (busy)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _UploadProgress(
                    current: state.uploadedCount,
                    total: state.filePhotoCount,
                  ),
                ),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.brandGold,
                    foregroundColor: AppColors.brandInk,
                    disabledBackgroundColor:
                        AppColors.brandGold.withValues(alpha: 0.55),
                    disabledForegroundColor: AppColors.brandInk
                        .withValues(alpha: 0.5),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: busy ? null : _submit,
                  child: busy
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppColors.brandInk,
                          ),
                        )
                      : const Text(
                          'PUBLICAR SPOT',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
    );
  }
}

InputDecoration _inputDecoration({required String hint}) {
  return InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: Colors.white,
    contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.brandBeige),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.brandBeige),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.brandForest, width: 1.6),
    ),
    counterText: '',
  );
}

class _PhotosCard extends StatelessWidget {
  const _PhotosCard({
    required this.photos,
    required this.onPhotosChanged,
  });

  final List<PhotoItem> photos;
  final ValueChanged<List<PhotoItem>> onPhotosChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.brandBeige),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.camera_alt_outlined,
                    color: AppColors.brandForest),
                const SizedBox(width: 10),
                Text(
                  'Agregar fotos',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            PhotoPickerGrid(
              photos: photos,
              onPhotosChanged: onPhotosChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationField extends StatelessWidget {
  const _LocationField({
    required this.location,
    required this.onTap,
  });

  final LatLng? location;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasLocation = location != null;
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.brandBeige),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Icon(
                hasLocation
                    ? Icons.location_on
                    : Icons.search,
                color: hasLocation
                    ? AppColors.brandForest
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  hasLocation
                      ? '${location!.latitude.toStringAsFixed(5)}, '
                          '${location!.longitude.toStringAsFixed(5)}'
                      : 'Busca o coloca en el mapa',
                  style: TextStyle(
                    color: hasLocation
                        ? AppColors.brandInk
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight:
                        hasLocation ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.brandForest),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.brandForest : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.brandForest : AppColors.brandBeige,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.brandInk,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _MoreDetailsTile extends StatelessWidget {
  const _MoreDetailsTile({
    required this.state,
    required this.vm,
    required this.safetyCtrl,
  });

  final CreateSpotState state;
  final CreateSpotViewModel vm;
  final TextEditingController safetyCtrl;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
        splashColor: Colors.transparent,
      ),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.zero,
        iconColor: AppColors.brandForest,
        collapsedIconColor: AppColors.brandForest,
        title: Text(
          'Mas detalles (opcional)',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        children: [
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: SpotDifficulty.values.map((d) {
              final selected = state.difficulty == d;
              return _TypeChip(
                label: d.label,
                selected: selected,
                onTap: () => vm.setDifficulty(d),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: BestTimeSlot.values.map((b) {
              final selected = state.bestTime.contains(b);
              return _TypeChip(
                label: b.label,
                selected: selected,
                onTap: () => vm.toggleBestTime(b),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: safetyCtrl,
            decoration: _inputDecoration(
              hint: 'Notas de seguridad...',
            ),
            maxLines: 2,
            maxLength: 240,
          ),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.icon,
    required this.text,
    this.error = false,
  });

  final IconData icon;
  final String text;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: error
            ? theme.colorScheme.errorContainer
            : theme.colorScheme.errorContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _UploadProgress extends StatelessWidget {
  const _UploadProgress({required this.current, required this.total});
  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 1.0 : (current / total).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Subiendo fotos $current de ${total == 0 ? 'skipped' : total}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(value: pct),
      ],
    );
  }
}