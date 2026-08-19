import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import 'package:spot_for_fun/ui/shared/utils/location_helper.dart';

@immutable
class MapViewState {
  const MapViewState({
    this.currentLocation,
    this.hasRealLocation = false,
    this.locating = false,
    this.bootstrapped = false,
  });

  final LatLng? currentLocation;
  final bool hasRealLocation;
  final bool locating;
  final bool bootstrapped;

  const MapViewState.initial() : this();

  MapViewState copyWith({
    LatLng? currentLocation,
    bool? hasRealLocation,
    bool? locating,
    bool? bootstrapped,
  }) {
    return MapViewState(
      currentLocation: currentLocation ?? this.currentLocation,
      hasRealLocation: hasRealLocation ?? this.hasRealLocation,
      locating: locating ?? this.locating,
      bootstrapped: bootstrapped ?? this.bootstrapped,
    );
  }
}

class MapViewModel extends Notifier<MapViewState> {
  @override
  MapViewState build() => const MapViewState.initial();

  Future<LocationStatus> bootstrapLocation() async {
    if (state.bootstrapped) return LocationStatus.granted;
    final status = await locateAndCenter(zoom: 14);
    state = state.copyWith(bootstrapped: true);
    return status;
  }

  Future<LocationStatus> recenter() => locateAndCenter(zoom: 15);

  Future<LocationStatus> locateAndCenter({required double zoom}) async {
    state = state.copyWith(locating: true);
    final status = await LocationHelper.ensurePermission();

    if (status == LocationStatus.granted) {
      final pos = await LocationHelper.currentPosition();
      if (pos != null) {
        final loc = LatLng(pos.latitude, pos.longitude);
        state = state.copyWith(
          locating: false,
          currentLocation: loc,
          hasRealLocation: true,
        );
        return status;
      }
      state = state.copyWith(locating: false);
      // Treat as if service off — GPS isn't producing a fix.
      return LocationStatus.serviceOff;
    }

    state = state.copyWith(locating: false);
    return status;
  }
}

final mapViewModelProvider =
    NotifierProvider<MapViewModel, MapViewState>(MapViewModel.new);
