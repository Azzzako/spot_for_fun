import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import 'package:spot_for_fun/ui/core/router/app_router.dart';
import 'package:spot_for_fun/domain/models/spot.dart';
import 'package:spot_for_fun/ui/core/theme/app_colors.dart';
import 'package:spot_for_fun/ui/shared/utils/location_helper.dart';
import 'package:spot_for_fun/ui/shared/widgets/spot_marker.dart';
import 'package:spot_for_fun/data/repositories/spot_repository.dart';
import 'package:spot_for_fun/ui/features/map/view_models/map_view_model.dart';
import 'package:spot_for_fun/ui/features/map/widgets/filters_sheet.dart';
import 'package:spot_for_fun/ui/features/map/widgets/spot_peek_card.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final _mapController = MapController();
  double _currentZoom = 15;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    final status = await ref
        .read(mapViewModelProvider.notifier)
        .bootstrapLocation();
    if (!mounted) return;
    if (status == LocationStatus.granted) {
      final loc = ref.read(mapViewModelProvider).currentLocation;
      if (loc != null) _mapController.move(loc, 16);
    }
    _showSnackForStatus(status);
  }

  Future<void> _recenter() async {
    final status = await ref.read(mapViewModelProvider.notifier).recenter();
    if (!mounted) return;
    if (status == LocationStatus.granted) {
      final loc = ref.read(mapViewModelProvider).currentLocation;
      if (loc != null) _mapController.move(loc, 17);
    }
    _showSnackForStatus(status);
  }

  void _showSnackForStatus(LocationStatus status) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    switch (status) {
      case LocationStatus.serviceOff:
        messenger.showSnackBar(
          SnackBar(
            content: const Text('Activa tu GPS para mostrar tu ubicación'),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Configurar',
              onPressed: () => LocationHelper.openLocationSettings(),
            ),
          ),
        );
        break;
      case LocationStatus.denied:
        messenger.showSnackBar(
          SnackBar(
            content: const Text('Sin permiso de ubicación'),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Reintentar',
              onPressed: _recenter,
            ),
          ),
        );
        break;
      case LocationStatus.deniedForever:
        messenger.showSnackBar(
          SnackBar(
            content: const Text('Permiso de ubicación bloqueado'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 8),
            action: SnackBarAction(
              label: 'Abrir ajustes',
              onPressed: () => LocationHelper.openAppSettings(),
            ),
          ),
        );
        break;
      case LocationStatus.error:
        messenger.showSnackBar(
          SnackBar(
            content: const Text('Error al acceder a la ubicación'),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Reintentar',
              onPressed: _recenter,
            ),
          ),
        );
        break;
      case LocationStatus.granted:
        break;
    }
  }

  void _openFilters() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      enableDrag: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (_) => const FiltersSheet(),
    );
  }

  Future<void> _showSpotPeek(Spot spot) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (ctx) => SpotPeekCard(
        spot: spot,
        onClose: () => Navigator.of(ctx).pop(),
        onViewDetail: () {
          Navigator.of(ctx).pop();
          context.push(AppRoutes.spotDetail(spot.id));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mapViewModelProvider);
    final spotsAsync = ref.watch(approvedSpotsProvider);
    final brightness = Theme.of(context).brightness;
    final filter = ref.watch(spotFilterProvider);
    final theme = Theme.of(context);
    final showLabels = _currentZoom >= 14;

    final activeChips = <Widget>[
      if (filter.types.isNotEmpty)
        _activeBadge(
          context,
          label: 'Tipo: ${filter.types.length}',
          onClear: () => ref.read(spotFilterProvider.notifier).state =
              filter.copyWith(types: const {}),
        ),
      if (filter.difficulties.isNotEmpty)
        _activeBadge(
          context,
          label: 'Dif: ${filter.difficulties.length}',
          onClear: () => ref.read(spotFilterProvider.notifier).state =
              filter.copyWith(difficulties: const {}),
        ),
      if (filter.minRating > 0)
        _activeBadge(
          context,
          label: '≥ ${filter.minRating.toStringAsFixed(1)}★',
          onClear: () => ref.read(spotFilterProvider.notifier).state =
              filter.copyWith(minRating: 0),
        ),
    ];

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter:
                  state.currentLocation ?? LocationHelper.neutralCenter,
              initialZoom: 15,
              minZoom: 3,
              maxZoom: 19,
              onPositionChanged: (pos, _) {
                final z = pos.zoom;
                if (z != _currentZoom) {
                  setState(() => _currentZoom = z);
                }
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
                  if (state.hasRealLocation && state.currentLocation != null)
                    Marker(
                      point: state.currentLocation!,
                      width: 32,
                      height: 32,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.brandForest,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: const Icon(Icons.person_pin_circle,
                            color: Colors.white, size: 16),
                      ),
                    ),
                  ...spotsAsync.when(
                    data: (spots) => spots.map((s) {
                      final kind = resolveSpotKind(s);
                      return Marker(
                        point: LatLng(s.lat, s.lng),
                        width: kSpotMarkerWidth,
                        height: kSpotMarkerHeight,
                        alignment: Alignment.topCenter,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _showSpotPeek(s),
                          child: spotMarkerWidget(
                            kind: kind,
                            brightness: brightness,
                            label: s.name,
                            showLabel: showLabels,
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
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: _ExplorarHeader(
                  onFilterTap: _openFilters,
                  filterCount: filter.types.length +
                      filter.difficulties.length +
                      (filter.minRating > 0 ? 1 : 0),
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
                children: activeChips,
              ),
            ),
          ),
          if (spotsAsync.hasError)
            Positioned(
              top: MediaQuery.of(context).padding.top + 76,
              left: 16,
              right: 16,
              child: Material(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, size: 18),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text('No se pudieron cargar los spots'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, size: 18),
                        onPressed: () =>
                            ref.invalidate(approvedSpotsProvider),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 88),
        child: FloatingActionButton.small(
          heroTag: 'recenter',
          backgroundColor: theme.colorScheme.surface,
          foregroundColor: theme.colorScheme.onSurface,
          elevation: 4,
          onPressed: state.locating ? null : _recenter,
          child: state.locating
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.my_location),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _activeBadge(
    BuildContext context, {
    required String label,
    required VoidCallback onClear,
  }) {
    return InputChip(
      label: Text(label),
      onDeleted: onClear,
      deleteIcon: const Icon(Icons.close, size: 16),
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 2,
    );
  }
}

class _ExplorarHeader extends StatelessWidget {
  const _ExplorarHeader({
    required this.onFilterTap,
    required this.filterCount,
  });

  final VoidCallback onFilterTap;
  final int filterCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      elevation: 2,
      borderRadius: BorderRadius.circular(18),
      shadowColor: Colors.black.withValues(alpha: 0.18),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Explorar',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                ),
                Material(
                  color: theme.colorScheme.surface,
                  shape: const CircleBorder(),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        tooltip: 'Filtros',
                        icon: const Icon(Icons.tune_rounded),
                        onPressed: onFilterTap,
                      ),
                      if (filterCount > 0)
                        Positioned(
                          right: 6,
                          top: 6,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.6),
                  ),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Icon(
                      Icons.search,
                      size: 20,
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Buscar spots',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.55),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
