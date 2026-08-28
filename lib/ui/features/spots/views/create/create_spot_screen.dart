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
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: busy ? null : () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Agregar spot'),
        actions: [
          IconButton(
            tooltip: 'Compartir borrador',
            icon: const Icon(Icons.ios_share_rounded),
            onPressed: busy
                ? null
                : () => _snack('Compartir · próximamente'),
          ),
          const SizedBox(width: 4),
        ],
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
                    const SizedBox(height: 12),
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
                        onPressed: busy ? null : _submit,
                        child: busy
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Publicar spot'),
                      ),
                    ),
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
      text,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
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
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.camera_alt_outlined,
                  color: theme.colorScheme.onSurface),
              const SizedBox(width: 10),
              Text(
                'Agregar fotos',
                style: theme.textTheme.titleMedium?.copyWith(
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
    final theme = Theme.of(context);
    return Container(
      height: 200,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: FlutterMap(
              mapController: controller,
              options: MapOptions(
                initialCenter: location ?? LocationHelper.neutralCenter,
                initialZoom: 16,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.pinchZoom |
                      InteractiveFlag.drag |
                      InteractiveFlag.doubleTapZoom,
                ),
                onTap: (_, point) => onPick(point),
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.spotforfun.app',
                  tileProvider: NetworkTileProvider(),
                ),
                if (location != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: location!,
                        width: 32,
                        height: 32,
                        child: const Icon(
                          Icons.location_on,
                          size: 32,
                          color: AppColors.brandForest,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          if (!hydrated || relocating)
            Container(
              color: Colors.black.withValues(alpha: 0.15),
              alignment: Alignment.center,
              child: const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              ),
            ),
          Positioned(
            right: 8,
            top: 8,
            child: Material(
              color: theme.colorScheme.surface,
              shape: const CircleBorder(),
              elevation: 2,
              child: IconButton(
                tooltip: 'Reubicar',
                icon: Icon(Icons.my_location,
                    color: theme.colorScheme.primary),
                onPressed: relocating ? null : onRelocate,
              ),
            ),
          ),
        ],
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
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurface,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
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
    final theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(
        dividerColor: Colors.transparent,
        splashColor: Colors.transparent,
      ),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.zero,
        iconColor: theme.colorScheme.primary,
        collapsedIconColor: theme.colorScheme.primary,
        title: Text(
          'Más detalles (opcional)',
          style: theme.textTheme.titleSmall?.copyWith(
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
          if (state.difficulty == null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Selecciona una dificultad.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
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
          TextField(
            controller: safetyCtrl,
            decoration: const InputDecoration(
              hintText: 'Notas de seguridad...',
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
