import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import 'package:spot_for_fun/ui/core/router/app_router.dart';
import 'package:spot_for_fun/ui/core/theme/app_colors.dart';
import 'package:spot_for_fun/domain/enums.dart';
import 'package:spot_for_fun/ui/shared/utils/location_helper.dart';
import 'package:spot_for_fun/ui/shared/widgets/photo_picker_grid.dart';
import 'package:spot_for_fun/ui/features/spots/view_models/create_spot_view_model.dart';
import 'package:spot_for_fun/ui/core/theme/app_theme.dart';
import 'package:spot_for_fun/ui/shared/widgets/spot_marker.dart';
import 'package:spot_for_fun/ui/shared/widgets/urban_chip.dart';
import 'package:spot_for_fun/ui/shared/widgets/urban_map.dart';

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
  final MapController _mapController = MapController();
  bool _hydrated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final loc = await ref
          .read(createSpotViewModelProvider.notifier)
          .initLocation();
      if (!mounted) {
        setState(() => _hydrated = true);
        return;
      }
      if (loc != null) {
        _mapController.move(loc, 16);
      }
      setState(() => _hydrated = true);
    });
  }

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
      _snack('Tu spot está en revisión');
      context.go(AppRoutes.profile);
    } else if (after == SubmitState.error &&
        ref.read(createSpotViewModelProvider).errorMessage != null) {
      _snack(ref.read(createSpotViewModelProvider).errorMessage!);
    }
  }

  void _finishWithoutMissingPhotos() {
    _snack('Tu spot está en revisión');
    context.go(AppRoutes.profile);
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
    final locked = state.isSpotCreated;
    final canSubmit =
        !busy && state.photos.isNotEmpty;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Cerrar',
          icon: const Icon(Icons.close),
          onPressed: busy ? null : () => Navigator.of(context).maybePop(),
        ),
        title: const Text('AGREGAR SPOT'),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Once the spot exists only the missing photos can be
                    // retried; editing these fields would have no effect.
                    AbsorbPointer(
                      absorbing: locked,
                      child: Opacity(
                        opacity: locked ? 0.55 : 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _PhotosCard(
                              photos: state.photos,
                              onPhotosChanged: vm.setPhotos,
                            ),
                            const SizedBox(height: 20),
                            _Label('Nombre del spot'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _nameCtrl,
                              decoration: const InputDecoration(
                                hintText: 'Ej. Escaleras del Parque',
                              ),
                              maxLength: 80,
                              textInputAction: TextInputAction.next,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Requerido';
                                }
                                if (v.trim().length < 3) {
                                  return 'Mínimo 3 caracteres';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            _Label('Tipo de spot'),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 6,
                              runSpacing: 8,
                              children: SpotType.values.map((t) {
                                final selected = state.type == t;
                                return UrbanChip(
                                  label: t.label,
                                  selected: selected,
                                  onTap: () => vm.setType(t),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 20),
                            _Label('Ubicación en el mapa'),
                            const SizedBox(height: 8),
                            _LocationPreview(
                              location: state.pickedLocation,
                              controller: _mapController,
                              onPick: vm.setPickedLocation,
                              hydrated: _hydrated,
                              relocating: state.locating,
                              onRelocate: () async {
                                final loc = await vm.relocateFromGps();
                                if (!mounted || loc == null) return;
                                _mapController.move(loc, 16);
                              },
                            ),
                            const SizedBox(height: 20),
                            _Label('Descripción'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _descCtrl,
                              decoration: const InputDecoration(
                                hintText: 'Cuéntanos algo sobre el spot...',
                              ),
                              maxLines: 3,
                              maxLength: 500,
                            ),
                            const SizedBox(height: 20),
                            _Label('Nivel'),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 6,
                              runSpacing: 8,
                              children: SpotDifficulty.values.map((d) {
                                final selected = state.difficulty == d;
                                return UrbanChip(
                                  label: d.label,
                                  selected: selected,
                                  onTap: () => vm.setDifficulty(d),
                                );
                              }).toList(),
                            ),
                            if (state.difficulty == null)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  'Selecciona un nivel.',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.error,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 20),
                            _Label('Mejor hora para ir'),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 6,
                              runSpacing: 8,
                              children: BestTimeSlot.values.map((b) {
                                final selected = state.bestTime.contains(b);
                                return UrbanChip(
                                  label: b.label,
                                  selected: selected,
                                  onTap: () => vm.toggleBestTime(b),
                                );
                              }).toList(),
                            ),
                            if (state.bestTime.isEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  'Selecciona al menos un horario.',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.error,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 20),
                            _Label('Notas de seguridad (opcional)'),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _safetyCtrl,
                              decoration: const InputDecoration(
                                hintText: 'Notas de seguridad...',
                              ),
                              maxLines: 2,
                              maxLength: 240,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (state.submitState == SubmitState.partialSuccess)
                      _Banner(
                        icon: Icons.warning_amber_rounded,
                        text: state.errorMessage ?? '',
                      ),
                    if (state.submitState == SubmitState.error &&
                        state.errorMessage != null)
                      _Banner(
                        icon: Icons.error_outline,
                        text: state.errorMessage!,
                        error: true,
                      ),
                    if (busy)
                      Padding(
                        padding: const EdgeInsets.only(top: 12, bottom: 4),
                        child: _UploadProgress(
                          current: state.uploadedCount,
                          total: state.filePhotoCount,
                        ),
                      ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 56,
                      child: FilledButton(
                        onPressed: canSubmit ? _submit : null,
                        child: busy
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: AppColors.asphalt,
                                ),
                              )
                            : Text(
                                locked ? 'REINTENTAR FOTOS' : 'PUBLICAR SPOT',
                              ),
                      ),
                    ),
                    if (locked &&
                        !busy &&
                        state.uploadedPhotoIndexes.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: _finishWithoutMissingPhotos,
                          child: const Text('CONTINUAR SIN ELLAS'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: AppTheme.label(12, color: AppColors.boneMuted),
    );
  }
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const _Label('Fotos'),
            const Spacer(),
            Text(
              'MÍNIMO 1 · MÁXIMO 3',
              style: AppTheme.label(10, color: AppColors.boneMuted),
            ),
          ],
        ),
        const SizedBox(height: 10),
        PhotoPickerGrid(
          photos: photos,
          onPhotosChanged: onPhotosChanged,
          maxPhotos: 3,
        ),
      ],
    );
  }
}

class _LocationPreview extends StatelessWidget {
  const _LocationPreview({
    required this.location,
    required this.controller,
    required this.onPick,
    required this.hydrated,
    required this.relocating,
    required this.onRelocate,
  });

  final LatLng? location;
  final MapController controller;
  final ValueChanged<LatLng> onPick;
  final bool hydrated;
  final bool relocating;
  final VoidCallback onRelocate;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 220,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.asphalt,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppColors.lineStrong, width: 1.5),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: FlutterMap(
                  mapController: controller,
                  options: MapOptions(
                    initialCenter: location ?? LocationHelper.neutralCenter,
                    initialZoom: 16,
                    backgroundColor: AppColors.asphalt,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.pinchZoom |
                          InteractiveFlag.drag |
                          InteractiveFlag.doubleTapZoom,
                    ),
                    onTap: (_, point) => onPick(point),
                  ),
                  children: [
                    const UrbanTileLayer(),
                    if (location != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: location!,
                            width: 44,
                            height: 44,
                            child: const SpotRhombusMarker(selected: true),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              if (!hydrated || relocating)
                const ColoredBox(
                  color: Color(0x55111111),
                  child: Center(
                    child: SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.4),
                    ),
                  ),
                ),
              Positioned(
                right: 8,
                top: 8,
                child: Tooltip(
                  message: 'Usar mi ubicación',
                  child: Material(
                    color: AppColors.asphalt,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                      side: const BorderSide(
                        color: AppColors.lineStrong,
                        width: 1.5,
                      ),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(4),
                      onTap: relocating ? null : onRelocate,
                      child: const SizedBox(
                        width: 44,
                        height: 44,
                        child: Icon(Icons.my_location, color: AppColors.tape),
                      ),
                    ),
                  ),
                ),
              ),
              const Positioned(left: 6, bottom: 6, child: OsmAttribution()),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Toca el mapa para mover el rombo al lugar exacto.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.boneMuted,
              ),
        ),
      ],
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
        color: AppColors.concrete,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: error ? AppColors.danger : AppColors.tape,
          width: 1.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: error ? AppColors.danger : AppColors.tape),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
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
          'SUBIENDO FOTOS $current DE $total',
          style: AppTheme.label(11, color: AppColors.boneMuted),
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(value: pct),
      ],
    );
  }
}
