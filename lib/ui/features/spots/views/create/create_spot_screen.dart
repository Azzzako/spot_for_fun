import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:spot_for_fun/ui/core/router/app_router.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrapLocation());
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _safetyCtrl.dispose();
    super.dispose();
  }

  Future<void> _bootstrapLocation() async {
    final loc = await ref
        .read(createSpotViewModelProvider.notifier)
        .initLocation();
    if (!mounted || loc == null) return;
    _mapController.move(loc, 17);
  }

  Future<void> _relocateFromGps() async {
    final loc = await ref
        .read(createSpotViewModelProvider.notifier)
        .relocateFromGps();
    if (!mounted || loc == null) return;
    _mapController.move(loc, 18);
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
    } else if (after == SubmitState.error && ref.read(createSpotViewModelProvider).errorMessage != null) {
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
      extendBodyBehindAppBar: true,
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text('Nuevo spot'),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: state.pickedLocation ?? LocationHelper.neutralCenter,
                initialZoom: 17,
                onTap: (_, point) {
                  vm.setPickedLocation(point);
                  _mapController.move(point, _mapController.camera.zoom);
                },
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.spotforfun.app',
                  tileProvider: NetworkTileProvider(),
                ),
                MarkerLayer(
                  markers: [
                    if (state.pickedLocation != null)
                      Marker(
                        point: state.pickedLocation!,
                        width: 48,
                        height: 48,
                        child: const Icon(
                          Icons.location_on,
                          size: 44,
                          color: Colors.redAccent,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (state.locating)
            const Center(
              child: SizedBox(
                height: 28,
                width: 28,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            ),
          Positioned(
            bottom: 8,
            right: 8,
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).size.height * 0.12 + 8,
              ),
              child: Material(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                child: IconButton(
                  icon: const Icon(Icons.my_location),
                  tooltip: 'Reubicar',
                  onPressed: state.locating ? null : _relocateFromGps,
                ),
              ),
            ),
          ),
          const Positioned(
            left: 12,
            top: 76,
            child: _MapHint(text: 'Toca o arrastra el mapa'),
          ),
          DraggableScrollableSheet(
            initialChildSize: 0.55,
            minChildSize: 0.12,
            maxChildSize: 0.92,
            snap: true,
            snapSizes: const [0.12, 0.55, 0.92],
            builder: (ctx, scrollController) {
              final bottomInset = MediaQuery.of(context).viewInsets.bottom;
              return Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 16,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottomInset),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        Text(
                          state.pickedLocation == null
                              ? 'Toca el mapa para fijar el spot'
                              : 'En ${state.pickedLocation!.latitude.toStringAsFixed(5)}, '
                                  '${state.pickedLocation!.longitude.toStringAsFixed(5)}',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _nameCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Nombre *',
                            prefixIcon: Icon(Icons.label_outline),
                          ),
                          maxLength: 80,
                          textInputAction: TextInputAction.next,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Requerido';
                            }
                            if (v.trim().length < 3) {
                              return 'Minimo 3 caracteres';
                            }
                            return null;
                          },
                        ),
                        TextFormField(
                          controller: _descCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Descripcion',
                            prefixIcon: Icon(Icons.notes),
                            alignLabelWithHint: true,
                          ),
                          maxLines: 3,
                          maxLength: 500,
                        ),
                        const SizedBox(height: 8),
                        _SectionLabel('Tipo de spot'),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: SpotType.values.map((t) {
                            return ChoiceChip(
                              label: Text(t.label),
                              selected: state.type == t,
                              onSelected: (_) => vm.setType(t),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 12),
                        _SectionLabel('Dificultad'),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: SpotDifficulty.values.map((d) {
                            return ChoiceChip(
                              label: Text(d.label),
                              selected: state.difficulty == d,
                              onSelected: (_) => vm.setDifficulty(d),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 12),
                        _SectionLabel('Mejor horario *'),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: BestTimeSlot.values.map((b) {
                            return FilterChip(
                              label: Text(b.label),
                              selected: state.bestTime.contains(b),
                              onSelected: (_) => vm.toggleBestTime(b),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                        _SectionLabel('Notas de seguridad (opcional)'),
                        TextFormField(
                          controller: _safetyCtrl,
                          decoration: const InputDecoration(
                            hintText:
                                'Ej. "Cuidado con los vecinos despues de las 8pm"',
                            prefixIcon: Icon(Icons.warning_amber_rounded),
                          ),
                          maxLines: 2,
                          maxLength: 240,
                        ),
                        const SizedBox(height: 12),
                        _SectionLabel('Fotos'),
                        PhotoPickerGrid(
                          photos: state.photos,
                          onPhotosChanged: vm.setPhotos,
                        ),
                        const SizedBox(height: 16),
                        if (busy)
                          _UploadProgress(
                            current: state.uploadedCount,
                            total: state.filePhotoCount,
                          ),
                        if (state.submitState == SubmitState.partialSuccess)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.errorContainer
                                  .withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.warning_amber_rounded,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Spot creado, pero algunas fotos fallaron:\n'
                                    '${state.errorMessage ?? ''}',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (state.submitState == SubmitState.error &&
                            state.errorMessage != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.error_outline, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(state.errorMessage!),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: busy ? null : _submit,
                          icon: busy
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.send_outlined),
                          label: Text(
                            busy ? 'Enviando...' : 'Enviar a revision',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 4),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleSmall,
      ),
    );
  }
}

class _MapHint extends StatelessWidget {
  const _MapHint({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 12),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Subiendo fotos $current de ${total == 0 ? 'skipped' : total}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(value: pct),
        ],
      ),
    );
  }
}
