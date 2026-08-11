import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/providers/theme_mode_pref_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/utils/location_helper.dart';
import '../../../shared/widgets/spot_marker.dart';
import '../../spots/data/spot_repository.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final _mapController = MapController();
  LatLng _currentLocation = const LatLng(19.4326, -99.1332);
  bool _locating = false;
  bool _centered = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureInitialLocation());
  }

  Future<void> _ensureInitialLocation() async {
    if (_centered) return;
    setState(() => _locating = true);
    final pos = await LocationHelper.currentOrFallback(fallback: _currentLocation);
    if (!mounted) return;
    setState(() {
      _currentLocation = pos;
      _locating = false;
      _centered = true;
    });
    _mapController.move(pos, 14);
  }

  Future<void> _recenter() async {
    setState(() => _locating = true);
    final pos = await LocationHelper.currentOrFallback(fallback: _currentLocation);
    if (!mounted) return;
    setState(() {
      _currentLocation = pos;
      _locating = false;
    });
    _mapController.move(pos, 15);
  }

  void _openFilters() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => const _FiltersSheet(),
    );
  }

  void _toggleTheme() {
    final theme = ref.read(themeModePrefProvider);
    final next = switch (theme.mode) {
      ThemeModePref.system => ThemeModePref.light,
      ThemeModePref.light => ThemeModePref.dark,
      ThemeModePref.dark => ThemeModePref.system,
    };
    theme.setMode(next);
  }

  @override
  Widget build(BuildContext context) {
    final spotsAsync = ref.watch(approvedSpotsProvider);
    final brightness = Theme.of(context).brightness;
    final filter = ref.watch(spotFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Spot For Fun'),
        actions: [
          IconButton(
            tooltip: 'Tema',
            onPressed: _toggleTheme,
            icon: const Icon(Icons.brightness_6_outlined),
          ),
          IconButton(
            tooltip: 'Mis spots',
            onPressed: () => context.push(AppRoutes.mySpots),
            icon: const Icon(Icons.list_alt_outlined),
          ),
          IconButton(
            tooltip: 'Perfil',
            onPressed: () => context.push(AppRoutes.profile),
            icon: const Icon(Icons.person_outline),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation,
              initialZoom: 13,
              minZoom: 3,
              maxZoom: 19,
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
                    point: _currentLocation,
                    width: 32,
                    height: 32,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: const Icon(Icons.person_pin_circle,
                          color: Colors.white, size: 16),
                    ),
                  ),
                  ...spotsAsync.when(
                    data: (spots) => spots.map((s) {
                      final kind = classifySpotKind(s.type.dbValue);
                      return Marker(
                        point: LatLng(s.lat, s.lng),
                        width: 48,
                        height: 48,
                        child: GestureDetector(
                          onTap: () =>
                              context.push(AppRoutes.spotDetail(s.id)),
                          child: spotMarkerWidget(
                            color: spotColorFor(kind, brightness),
                            icon: spotIconFor(kind),
                          ),
                        ),
                      );
                    }).toList(),
                    loading: () => const [],
                    error: (_, _) => const [],
                  ),
                ],
              ),
            ],
          ),
          if (spotsAsync.isLoading)
            const Positioned(
              top: 12,
              left: 12,
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          if (spotsAsync.hasError)
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Material(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, size: 18),
                      const SizedBox(width: 8),
                      const Expanded(child: Text('No se pudieron cargar los spots')),
                      IconButton(
                        icon: const Icon(Icons.refresh, size: 18),
                        onPressed: () => ref.invalidate(approvedSpotsProvider),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 96,
            child: Center(
              child: Wrap(
                spacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  if (filter.types.isNotEmpty)
                    _filterBadge(
                      label: 'Tipo: ${filter.types.length}',
                      onClear: () =>
                          ref.read(spotFilterProvider.notifier).state =
                              filter.copyWith(types: const {}),
                    ),
                  if (filter.difficulties.isNotEmpty)
                    _filterBadge(
                      label: 'Dif: ${filter.difficulties.length}',
                      onClear: () =>
                          ref.read(spotFilterProvider.notifier).state =
                              filter.copyWith(difficulties: const {}),
                    ),
                  if (filter.minRating > 0)
                    _filterBadge(
                      label: '≥ ${filter.minRating.toStringAsFixed(1)}★',
                      onClear: () =>
                          ref.read(spotFilterProvider.notifier).state =
                              filter.copyWith(minRating: 0),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            heroTag: 'recenter',
            onPressed: _locating ? null : _recenter,
            child: _locating
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'create',
            onPressed: () => context.push(AppRoutes.spotCreate),
            child: const Icon(Icons.add_location_alt_outlined),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: FilledButton.tonalIcon(
            onPressed: _openFilters,
            icon: const Icon(Icons.filter_alt_outlined),
            label: const Text('Filtros'),
          ),
        ),
      ),
    );
  }

  Widget _filterBadge({required String label, required VoidCallback onClear}) {
    return InputChip(
      label: Text(label),
      onDeleted: onClear,
      deleteIcon: const Icon(Icons.close, size: 16),
    );
  }
}

class _FiltersSheet extends ConsumerWidget {
  const _FiltersSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(spotFilterProvider);
    final notifier = ref.read(spotFilterProvider.notifier);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tipo', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: SpotType.values.map((t) {
                final selected = filter.types.contains(t);
                return FilterChip(
                  label: Text(t.label),
                  selected: selected,
                  onSelected: (_) {
                    final next = <SpotType>{...filter.types};
                    if (selected) {
                      next.remove(t);
                    } else {
                      next.add(t);
                    }
                    notifier.state = filter.copyWith(types: next);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Text('Dificultad', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: SpotDifficulty.values.map((d) {
                final selected = filter.difficulties.contains(d);
                return FilterChip(
                  label: Text(d.label),
                  selected: selected,
                  onSelected: (_) {
                    final next = <SpotDifficulty>{...filter.difficulties};
                    if (selected) {
                      next.remove(d);
                    } else {
                      next.add(d);
                    }
                    notifier.state = filter.copyWith(difficulties: next);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Text(
              'Rating mínimo: ${filter.minRating.toStringAsFixed(1)}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Slider(
              value: filter.minRating,
              min: 0,
              max: 5,
              divisions: 10,
              onChanged: (v) =>
                  notifier.state = filter.copyWith(minRating: v),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => notifier.state = const SpotFilter(),
                    child: const Text('Limpiar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Aplicar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
