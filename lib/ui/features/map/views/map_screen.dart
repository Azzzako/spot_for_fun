import 'dart:async';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import 'package:spot_for_fun/data/repositories/spot_repository.dart';
import 'package:spot_for_fun/data/services/spot_service.dart' show SpotFilter;
import 'package:spot_for_fun/domain/enums.dart';
import 'package:spot_for_fun/domain/models/spot.dart';
import 'package:spot_for_fun/ui/core/router/app_router.dart';
import 'package:spot_for_fun/ui/core/theme/app_colors.dart';
import 'package:spot_for_fun/ui/core/theme/app_theme.dart';
import 'package:spot_for_fun/ui/features/map/view_models/map_view_model.dart';
import 'package:spot_for_fun/ui/features/map/widgets/filters_sheet.dart';
import 'package:spot_for_fun/ui/features/social/view_models/social_view_model.dart';
import 'package:spot_for_fun/ui/shared/utils/location_helper.dart';
import 'package:spot_for_fun/ui/shared/widgets/spot_marker.dart';
import 'package:spot_for_fun/ui/shared/widgets/tape_label.dart';
import 'package:spot_for_fun/ui/shared/widgets/urban_chip.dart';
import 'package:spot_for_fun/ui/shared/widgets/urban_map.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final _mapController = MapController();
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  String _query = '';
  String? _selectedId;

  // Live location: the GPS runs only while the map is actually on screen
  // (its tab is active, nothing is pushed over it) and the app is in the
  // foreground. "Follow" keeps the camera on the user until they drag.
  late final MapViewModel _mapVm;
  late final AppLifecycleListener _lifecycle;
  bool _locationGranted = false;
  bool _onScreen = true;
  bool _inForeground = true;
  bool _following = false;

  // Spots load by area: what the map shows plus a margin, so small pans
  // and walking in follow mode are served from what's already loaded.
  static const _maxAreaM = 500000.0;
  static const _minFetchM = 1500.0;
  static const _distance = Distance();
  MapCamera? _camera;
  Timer? _areaDebounce;

  @override
  void initState() {
    super.initState();
    _mapVm = ref.read(mapViewModelProvider.notifier);
    _lifecycle = AppLifecycleListener(
      onShow: () {
        setState(() => _inForeground = true);
        _syncTracking();
        // Refreshes the current area if it went stale while away.
        _loadArea();
      },
      onHide: () {
        setState(() => _inForeground = false);
        _syncTracking();
      },
    );
    _searchFocus.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Inactive shell tabs and routes covered by another page have their
    // tickers disabled; use that as "the map isn't visible".
    final onScreen = TickerMode.valuesOf(context).enabled;
    if (onScreen != _onScreen) {
      _onScreen = onScreen;
      _syncTracking();
    }
  }

  void _onCameraChanged(MapCamera camera) {
    setState(() => _camera = camera);
    _areaDebounce?.cancel();
    _areaDebounce = Timer(const Duration(milliseconds: 350), _loadArea);
  }

  /// Asks for the circle around the screen (centre to corner); it's
  /// downloaded twice as big (at least [_minFetchM]) to leave a margin.
  void _loadArea({bool force = false}) {
    final camera = _camera;
    if (camera == null) return;
    final needM = math.min(
      _distance.as(
        LengthUnit.Meter,
        camera.center,
        camera.visibleBounds.northEast,
      ),
      _maxAreaM,
    );
    ref
        .read(spotCatalogProvider.notifier)
        .ensureArea(
          camera.center.latitude,
          camera.center.longitude,
          needM: needM,
          fetchM: math.min(math.max(needM * 2, _minFetchM), _maxAreaM),
          force: force,
        );
  }

  @override
  void dispose() {
    _areaDebounce?.cancel();
    _lifecycle.dispose();
    _mapVm.stopTracking();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _syncTracking() {
    if (_locationGranted && _onScreen && _inForeground) {
      _mapVm.startTracking();
    } else {
      _mapVm.stopTracking();
    }
  }

  Future<void> _bootstrap() async {
    final status = await _mapVm.bootstrapLocation();
    if (!mounted) return;
    if (status == LocationStatus.granted) {
      _locationGranted = true;
      _syncTracking();
      final loc = ref.read(mapViewModelProvider).currentLocation;
      if (loc != null) _mapController.move(loc, 17);
    }
    _showSnackForStatus(status);
  }

  /// Locate button: jump to the user and follow them from now on.
  Future<void> _onLocateTap() async {
    final known = ref.read(mapViewModelProvider).currentLocation;
    if (_mapVm.isTracking && known != null) {
      setState(() => _following = true);
      _mapController.move(known, _followZoom);
      return;
    }
    await _recenter();
  }

  double get _followZoom {
    final zoom = _mapController.camera.zoom;
    return zoom < 17 ? 17 : zoom;
  }

  Future<void> _recenter() async {
    final status = await _mapVm.recenter();
    if (!mounted) return;
    if (status == LocationStatus.granted) {
      _locationGranted = true;
      _syncTracking();
      final loc = ref.read(mapViewModelProvider).currentLocation;
      if (loc != null) {
        setState(() => _following = true);
        _mapController.move(loc, _followZoom);
      }
    }
    _showSnackForStatus(status);
  }

  void _showSnackForStatus(LocationStatus status) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    final (String text, String action, VoidCallback onAction)? snack =
        switch (status) {
          LocationStatus.serviceOff => (
            'Activa tu GPS para mostrar tu ubicación',
            'CONFIGURAR',
            LocationHelper.openLocationSettings,
          ),
          LocationStatus.denied => (
            'Sin permiso de ubicación',
            'REINTENTAR',
            _recenter,
          ),
          LocationStatus.deniedForever => (
            'Permiso de ubicación bloqueado',
            'ABRIR AJUSTES',
            LocationHelper.openAppSettings,
          ),
          LocationStatus.error => (
            'Error al acceder a la ubicación',
            'REINTENTAR',
            _recenter,
          ),
          LocationStatus.granted => null,
        };
    if (snack == null) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(snack.$1),
        duration: Duration(
          seconds: status == LocationStatus.deniedForever ? 8 : 4,
        ),
        action: SnackBarAction(label: snack.$2, onPressed: snack.$3),
      ),
    );
  }

  void _openFilters() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const FiltersSheet(),
    );
  }

  void _select(Spot spot, {bool moveCamera = false}) {
    setState(() => _selectedId = spot.id);
    if (moveCamera) {
      final zoom = _mapController.camera.zoom < 15
          ? 15.0
          : _mapController.camera.zoom;
      _mapController.move(LatLng(spot.lat, spot.lng), zoom);
    }
  }

  void _pickSearchResult(Spot spot) {
    _searchFocus.unfocus();
    _select(spot, moveCamera: true);
  }

  void _clearSearch() {
    _searchCtrl.clear();
    setState(() => _query = '');
  }

  void _toggleType(SpotFilter filter, SpotType type) {
    final next = <SpotType>{...filter.types};
    if (!next.remove(type)) next.add(type);
    ref.read(spotFilterProvider.notifier).state = filter.copyWith(types: next);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(mapViewModelProvider.select((s) => s.currentLocation), (
      _,
      next,
    ) {
      if (_following && next != null) {
        _mapController.move(next, _mapController.camera.zoom);
      }
    });
    final state = ref.watch(mapViewModelProvider);
    final catalog = ref.watch(spotCatalogProvider);
    final spots = ref.watch(approvedSpotsProvider);
    final filter = ref.watch(spotFilterProvider);

    final q = _query.trim().toLowerCase();
    final visible = q.isEmpty
        ? spots
        : spots.where((s) => s.name.toLowerCase().contains(q)).toList();
    // The header count only looks at what's on screen.
    final bounds = _camera?.visibleBounds;
    final inView = bounds == null
        ? null
        : visible.where((s) => bounds.contains(LatLng(s.lat, s.lng))).length;
    final settled = catalog.ready && !catalog.loading && inView != null;
    Spot? selected;
    for (final s in visible) {
      if (s.id == _selectedId) selected = s;
    }
    final showResults = _searchFocus.hasFocus && q.isNotEmpty;
    final showEmpty =
        settled && visible.isEmpty && (q.isNotEmpty || !filter.isEmpty);
    final secondaryFilters =
        filter.difficulties.length +
        filter.bestTime.length +
        (filter.minRating > 0 ? 1 : 0);

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              // North stays up, so the compass beam can use the raw
              // heading (and nobody rotates the map by accident).
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
              initialCenter:
                  state.currentLocation ?? LocationHelper.neutralCenter,
              // Close enough to read the streets.
              initialZoom: state.currentLocation != null
                  ? 17
                  : LocationHelper.neutralZoom,
              minZoom: 3,
              maxZoom: 19,
              backgroundColor: AppColors.asphalt,
              onMapReady: () => _onCameraChanged(_mapController.camera),
              onPositionChanged: (camera, hasGesture) {
                if (hasGesture && _following) _following = false;
                _onCameraChanged(camera);
              },
              onTap: (_, _) {
                _searchFocus.unfocus();
                if (_selectedId != null) setState(() => _selectedId = null);
              },
            ),
            children: [
              const UrbanTileLayer(),
              if (state.hasRealLocation && state.currentLocation != null)
                TweenAnimationBuilder<LatLng>(
                  // Glides between GPS fixes instead of jumping.
                  tween: _LatLngTween(
                    begin: state.currentLocation,
                    end: state.currentLocation,
                  ),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeInOutCubic,
                  builder: (context, point, _) => MarkerLayer(
                    markers: [
                      Marker(
                        point: point,
                        width: UserLocationDot.size,
                        height: UserLocationDot.size,
                        child: UserLocationDot(
                          showHeading:
                              _locationGranted && _onScreen && _inForeground,
                        ),
                      ),
                    ],
                  ),
                ),
              MarkerLayer(
                markers: [
                  for (final s in visible)
                    Marker(
                      point: LatLng(s.lat, s.lng),
                      width: 44,
                      height: 44,
                      child: Semantics(
                        button: true,
                        label: s.name,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _select(s),
                          child: SpotRhombusMarker(
                            selected: s.id == _selectedId,
                          ),
                        ),
                      ),
                    ),
                  if (selected != null)
                    Marker(
                      point: LatLng(selected.lat, selected.lng),
                      width: 220,
                      height: 60,
                      alignment: Alignment.topCenter,
                      child: IgnorePointer(
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: _PopIn(
                            key: ValueKey(selected.id),
                            child: TapeLabel(
                              selected.name,
                              fontSize: 13,
                              angleDegrees: -3,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ExploraHeader(
                  spotCount: catalog.ready ? inView : null,
                  searchCtrl: _searchCtrl,
                  searchFocus: _searchFocus,
                  onQueryChanged: (v) => setState(() => _query = v),
                  onClearSearch: _clearSearch,
                  onFilterTap: _openFilters,
                  secondaryFilterCount: secondaryFilters,
                  selectedTypes: filter.types,
                  onClearTypes: () =>
                      ref.read(spotFilterProvider.notifier).state = filter
                          .copyWith(types: const {}),
                  onToggleType: (t) => _toggleType(filter, t),
                  loading: catalog.loading,
                ),
                if (showResults)
                  _SearchResults(
                    results: visible.take(5).toList(),
                    onPick: _pickSearchResult,
                  ),
                if (catalog.failed && inView == 0 && !showResults)
                  _Banner(
                    text: 'No se pudieron cargar los spots',
                    action: 'REINTENTAR',
                    onAction: () => _loadArea(force: true),
                    error: true,
                  ),
                if (showEmpty && !showResults)
                  _Banner(
                    text: q.isNotEmpty
                        ? 'Ningún spot se llama así'
                        : 'Sin spots con estos filtros',
                    action: 'LIMPIAR',
                    onAction: () {
                      _clearSearch();
                      ref.read(spotFilterProvider.notifier).state =
                          const SpotFilter();
                    },
                  ),
              ],
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const OsmAttribution(),
                    const Spacer(),
                    _SquareButton(
                      tooltip: _following
                          ? 'Siguiendo tu ubicación'
                          : 'Centrar en mi ubicación',
                      onPressed: state.locating ? null : _onLocateTap,
                      child: state.locating
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              _following
                                  ? Icons.my_location
                                  : Icons.location_searching,
                              size: 22,
                              color: _following ? AppColors.tape : null,
                            ),
                    ),
                  ],
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 320),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween(
                        begin: const Offset(0, 0.25),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
                  child: selected == null
                      ? const SizedBox.shrink()
                      : Padding(
                          key: ValueKey(selected.id),
                          padding: const EdgeInsets.only(top: 12),
                          child: _SpotCard(
                            spot: selected,
                            from: state.hasRealLocation
                                ? state.currentLocation
                                : null,
                            onOpen: () => context.push(
                              AppRoutes.spotDetail(selected!.id),
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExploraHeader extends StatelessWidget {
  const _ExploraHeader({
    required this.spotCount,
    required this.searchCtrl,
    required this.searchFocus,
    required this.onQueryChanged,
    required this.onClearSearch,
    required this.onFilterTap,
    required this.secondaryFilterCount,
    required this.selectedTypes,
    required this.onClearTypes,
    required this.onToggleType,
    required this.loading,
  });

  /// Spots on screen right now.
  final int? spotCount;
  final TextEditingController searchCtrl;
  final FocusNode searchFocus;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onClearSearch;
  final VoidCallback onFilterTap;
  final int secondaryFilterCount;
  final Set<SpotType> selectedTypes;
  final VoidCallback onClearTypes;
  final ValueChanged<SpotType> onToggleType;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.asphalt,
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('EXPLORA', style: AppTheme.display(42)),
                  const Spacer(),
                  if (spotCount != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        spotCount == 1 ? '1 SPOT' : '$spotCount SPOTS',
                        style: AppTheme.label(12, color: AppColors.boneMuted),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: searchCtrl,
                      focusNode: searchFocus,
                      onChanged: onQueryChanged,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: 'Busca un spot…',
                        isDense: true,
                        prefixIcon: const Icon(Icons.search, size: 20),
                        suffixIcon: searchCtrl.text.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Borrar búsqueda',
                                icon: const Icon(Icons.close, size: 18),
                                onPressed: onClearSearch,
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Badge(
                    isLabelVisible: secondaryFilterCount > 0,
                    label: Text('$secondaryFilterCount'),
                    backgroundColor: AppColors.bone,
                    textColor: AppColors.asphalt,
                    child: _SquareButton(
                      tooltip: 'Filtros',
                      filled: true,
                      onPressed: onFilterTap,
                      child: const Icon(Icons.tune, size: 22),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 58,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                children: [
                  UrbanChip(
                    label: 'Todos',
                    selected: selectedTypes.isEmpty,
                    onTap: onClearTypes,
                  ),
                  for (final t in SpotType.values) ...[
                    const SizedBox(width: 6),
                    UrbanChip(
                      label: t.label,
                      selected: selectedTypes.contains(t),
                      onTap: () => onToggleType(t),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(
              height: 2,
              child: loading ? const LinearProgressIndicator() : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchResults extends StatelessWidget {
  const _SearchResults({required this.results, required this.onPick});

  final List<Spot> results;
  final ValueChanged<Spot> onPick;

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) return const SizedBox.shrink();
    return Material(
      color: AppColors.concrete,
      child: Column(
        children: [
          for (final s in results)
            InkWell(
              onTap: () => onPick(s),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.line)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.place_outlined,
                      size: 18,
                      color: AppColors.tape,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        s.name.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.display(18),
                      ),
                    ),
                    Text(
                      s.type.label.toUpperCase(),
                      style: AppTheme.label(11, color: AppColors.boneMuted),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.text,
    required this.action,
    required this.onAction,
    this.error = false,
  });

  final String text;
  final String action;
  final VoidCallback onAction;
  final bool error;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
      decoration: BoxDecoration(
        color: AppColors.concrete,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: error ? AppColors.danger : AppColors.lineStrong,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            error ? Icons.error_outline : Icons.search_off,
            size: 18,
            color: error ? AppColors.danger : AppColors.boneMuted,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
          TextButton(onPressed: onAction, child: Text(action)),
        ],
      ),
    );
  }
}

class _SpotCard extends ConsumerWidget {
  const _SpotCard({
    required this.spot,
    required this.from,
    required this.onOpen,
  });

  final Spot spot;
  final LatLng? from;
  final VoidCallback onOpen;

  String? get _distance {
    final origin = from;
    if (origin == null) return null;
    final meters = const Distance().as(
      LengthUnit.Meter,
      origin,
      LatLng(spot.lat, spot.lng),
    );
    if (meters < 1000) return '${meters.round()} M';
    return '${(meters / 1000).toStringAsFixed(1)} KM';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photo = spot.thumbUrl;
    final meta = [
      spot.difficulty.label.toUpperCase(),
      if (spot.ratingsCount > 0) '${spot.avgRating.toStringAsFixed(1)} ★',
      ?_distance,
    ].join(' · ');

    return Material(
      color: AppColors.concrete,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: const BorderSide(color: AppColors.line),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: InkWell(
                onTap: onOpen,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: 112,
                      child: photo == null
                          ? const ColoredBox(
                              color: AppColors.concreteHigh,
                              child: Icon(
                                Icons.image_not_supported_outlined,
                                color: AppColors.boneMuted,
                              ),
                            )
                          : CachedNetworkImage(
                              imageUrl: photo,
                              fit: BoxFit.cover,
                              placeholder: (_, _) => const ColoredBox(
                                color: AppColors.concreteHigh,
                              ),
                              errorWidget: (_, _, _) => const ColoredBox(
                                color: AppColors.concreteHigh,
                              ),
                            ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TapeLabel(spot.type.label, fontSize: 11),
                            const SizedBox(height: 10),
                            Text(
                              spot.name.toUpperCase(),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTheme.display(24),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              meta,
                              style: AppTheme.label(
                                11,
                                color: AppColors.boneMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            DecoratedBox(
              decoration: const BoxDecoration(
                border: Border(left: BorderSide(color: AppColors.line)),
              ),
              child: IconButton(
                tooltip: spot.isFavorited
                    ? 'Quitar de favoritos'
                    : 'Guardar en favoritos',
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final ok = await ref
                      .read(socialViewModelProvider.notifier)
                      .toggleFavorite(
                        spotId: spot.id,
                        currentlyFavorited: spot.isFavorited,
                      );
                  if (ok) return;
                  messenger
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      const SnackBar(
                        content: Text(
                          'No se pudo actualizar. Inténtalo de nuevo.',
                        ),
                      ),
                    );
                },
                icon: Icon(
                  spot.isFavorited ? Icons.bookmark : Icons.bookmark_border,
                  color: spot.isFavorited ? AppColors.tape : AppColors.bone,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SquareButton extends StatelessWidget {
  const _SquareButton({
    required this.tooltip,
    required this.onPressed,
    required this.child,
    this.filled = false,
  });

  final String tooltip;
  final VoidCallback? onPressed;
  final Widget child;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: filled ? AppColors.tape : AppColors.concrete,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: filled
              ? BorderSide.none
              : const BorderSide(color: AppColors.lineStrong, width: 1.5),
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            width: 50,
            height: 50,
            child: IconTheme(
              data: IconThemeData(
                color: filled ? AppColors.asphalt : AppColors.bone,
              ),
              child: Center(child: child),
            ),
          ),
        ),
      ),
    );
  }
}

class _LatLngTween extends Tween<LatLng> {
  _LatLngTween({super.begin, super.end});

  @override
  LatLng lerp(double t) => LatLng(
    begin!.latitude + (end!.latitude - begin!.latitude) * t,
    begin!.longitude + (end!.longitude - begin!.longitude) * t,
  );
}

/// Grows [child] out of its bottom edge with a small overshoot, the
/// same "pop" the selected rhombus does. Replays when the key changes.
class _PopIn extends StatelessWidget {
  const _PopIn({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) return child;
    return child
        .animate()
        .fadeIn(duration: 140.ms)
        .scale(
          begin: const Offset(0.2, 0.2),
          end: const Offset(1, 1),
          alignment: Alignment.bottomCenter,
          duration: 380.ms,
          curve: Curves.easeOutBack,
        );
  }
}
