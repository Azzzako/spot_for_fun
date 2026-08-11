import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/router/app_router.dart';
import '../../../../shared/models/enums.dart';
import '../../../../shared/utils/location_helper.dart';
import '../../../../shared/widgets/photo_picker_grid.dart';
import '../../data/spot_repository.dart';

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

  LatLng _picked = LocationHelper.neutralCenter;
  bool _locating = true;

  SpotType _type = SpotType.street;
  SpotDifficulty _difficulty = SpotDifficulty.beginner;
  final Set<BestTimeSlot> _bestTime = {};

  List<PhotoItem> _photos = const [
    PhotoItem.asset('assets/sample_spots/skate_01.jpg'),
    PhotoItem.asset('assets/sample_spots/skate_02.jpg'),
    PhotoItem.asset('assets/sample_spots/skate_03.jpg'),
    PhotoItem.asset('assets/sample_spots/skate_04.jpg'),
  ];

  SubmitState _state = SubmitState.idle;
  String? _errorMessage;
  int _uploadedCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initLocation());
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _safetyCtrl.dispose();
    super.dispose();
  }

  Future<void> _initLocation() async {
    final status = await LocationHelper.ensurePermission();
    if (!mounted) return;
    if (status == LocationStatus.granted) {
      final pos = await LocationHelper.currentPosition();
      if (!mounted) return;
      if (pos != null) {
        setState(() {
          _picked = LatLng(pos.latitude, pos.longitude);
          _locating = false;
        });
        _mapController.move(_picked, 15);
        return;
      }
    }
    setState(() => _locating = false);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_bestTime.isEmpty) {
      _snack('Selecciona al menos un mejor horario');
      return;
    }
    setState(() {
      _state = SubmitState.uploading;
      _uploadedCount = 0;
      _errorMessage = null;
    });

    final repo = ref.read(spotRepositoryProvider);
    try {
      final spot = await repo.createSpot(
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        lat: _picked.latitude,
        lng: _picked.longitude,
        type: _type,
        difficulty: _difficulty,
        bestTime: _bestTime.toList(),
        safetyNotes: _safetyCtrl.text.trim().isEmpty
            ? null
            : _safetyCtrl.text.trim(),
      );

      final photoErrors = <String>[];
      for (var i = 0; i < _photos.length; i++) {
        final photo = _photos[i];
        if (photo.source != PhotoSource.file) continue;
        try {
          final url = await repo.uploadSpotPhoto(
            spotId: spot.id,
            bytes: photo.bytes!,
            ext: photo.ext,
          );
          await repo.attachSpotPhoto(
            spotId: spot.id,
            url: url,
            position: i,
          );
          if (!mounted) return;
          setState(() => _uploadedCount = i + 1);
        } catch (e) {
          photoErrors.add('Foto ${i + 1}: $e');
        }
      }

      if (!mounted) return;
      if (photoErrors.isNotEmpty) {
        setState(() {
          _state = SubmitState.partialSuccess;
          _errorMessage = photoErrors.join('\n');
        });
        return;
      }

      setState(() => _state = SubmitState.success);
      await Future<void>.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      _snack('Tu spot esta en revision');
      context.go(AppRoutes.mySpots);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _state = SubmitState.error;
        _errorMessage = e.toString();
      });
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final busy = _state == SubmitState.uploading;
    final theme = Theme.of(context);

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
                initialCenter: _picked,
                initialZoom: 14,
                onTap: (_, point) => setState(() => _picked = point),
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
                    Marker(
                      point: _picked,
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
          if (_locating)
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
                  onPressed: _locating
                      ? null
                      : () async {
                          setState(() => _locating = true);
                          final pos = await LocationHelper.currentPosition();
                          if (!mounted) return;
                          if (pos != null) {
                            final pt = LatLng(pos.latitude, pos.longitude);
                            setState(() {
                              _picked = pt;
                              _locating = false;
                            });
                            _mapController.move(pt, 16);
                          } else {
                            setState(() => _locating = false);
                          }
                        },
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
                          'En ${_picked.latitude.toStringAsFixed(5)}, '
                          '${_picked.longitude.toStringAsFixed(5)}',
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
                              selected: _type == t,
                              onSelected: (_) => setState(() => _type = t),
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
                              selected: _difficulty == d,
                              onSelected: (_) =>
                                  setState(() => _difficulty = d),
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
                              selected: _bestTime.contains(b),
                              onSelected: (sel) => setState(() {
                                if (sel) {
                                  _bestTime.add(b);
                                } else {
                                  _bestTime.remove(b);
                                }
                              }),
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
                          photos: _photos,
                          onPhotosChanged: (next) =>
                              setState(() => _photos = next),
                        ),
                        const SizedBox(height: 16),
                        if (busy)
                          _UploadProgress(
                            current: _uploadedCount,
                            total: _photos
                                .where((p) => p.source == PhotoSource.file)
                                .length,
                          ),
                        if (_state == SubmitState.partialSuccess)
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
                                    '${_errorMessage ?? ''}',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (_state == SubmitState.error)
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
                                  child: Text(
                                    _errorMessage ?? 'Error desconocido',
                                  ),
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

enum SubmitState { idle, uploading, partialSuccess, success, error }
