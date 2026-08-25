import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:spot_for_fun/ui/shared/utils/location_helper.dart';
import 'package:spot_for_fun/ui/features/spots/view_models/create_spot_view_model.dart';

class SpotLocationPickerScreen extends ConsumerStatefulWidget {
  const SpotLocationPickerScreen({super.key});

  @override
  ConsumerState<SpotLocationPickerScreen> createState() =>
      _SpotLocationPickerScreenState();
}

class _SpotLocationPickerScreenState
    extends ConsumerState<SpotLocationPickerScreen> {
  final MapController _mapController = MapController();
  bool _hydrated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final loc = await ref
          .read(createSpotViewModelProvider.notifier)
          .initLocation();
      if (!mounted) return;
      if (loc != null) {
        _mapController.move(loc, 16);
      }
      setState(() => _hydrated = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createSpotViewModelProvider);
    final vm = ref.read(createSpotViewModelProvider.notifier);
    final theme = Theme.of(context);
    final loc = state.pickedLocation;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Selecciona la ubicacion'),
        backgroundColor: theme.colorScheme.surface,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: loc ?? LocationHelper.neutralCenter,
              initialZoom: 16,
              onTap: (_, point) {
                vm.setPickedLocation(point);
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
                  if (loc != null)
                    Marker(
                      point: loc,
                      width: 32,
                      height: 32,
                      child: const Icon(
                        Icons.location_on,
                        size: 30,
                        color: Colors.redAccent,
                      ),
                    ),
                ],
              ),
            ],
          ),
          if (state.locating || !_hydrated)
            const Center(
              child: SizedBox(
                height: 28,
                width: 28,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            ),
          Positioned(
            top: 12,
            right: 12,
            child: Material(
              color: theme.colorScheme.surface,
              shape: const CircleBorder(),
              elevation: 2,
              child: IconButton(
                tooltip: 'Reubicar',
                icon: const Icon(Icons.my_location),
                onPressed: state.locating
                    ? null
                    : () async {
                        final newLoc = await vm.relocateFromGps();
                        if (!mounted || newLoc == null) return;
                        _mapController.move(newLoc, 16);
                      },
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Material(
              color: theme.colorScheme.surface,
              elevation: 4,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      loc == null
                          ? 'Toca el mapa para fijar el spot'
                          : '${loc.latitude.toStringAsFixed(5)}, '
                              '${loc.longitude.toStringAsFixed(5)}',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton(
                        onPressed: loc == null
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: const Text('Confirmar ubicacion'),
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