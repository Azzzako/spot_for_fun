import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
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
  StreamSubscription<Position>? _tracking;

  @override
  MapViewState build() {
    ref.onDispose(() => _tracking?.cancel());
    return const MapViewState.initial();
  }

  bool get isTracking => _tracking != null;

  /// Follows the GPS while the map is on screen. Only call after a
  /// [LocationStatus.granted]; errors (GPS switched off, permission
  /// revoked) stop tracking and keep the last known position.
  void startTracking() {
    if (_tracking != null) return;
    _tracking = LocationHelper.positionStream().listen(
      (pos) => state = state.copyWith(
        currentLocation: LatLng(pos.latitude, pos.longitude),
        hasRealLocation: true,
      ),
      onError: (Object e) {
        debugPrint('[MapViewModel] tracking stopped: $e');
        stopTracking();
      },
    );
  }

  void stopTracking() {
    _tracking?.cancel();
    _tracking = null;
  }

  Future<LocationStatus> bootstrapLocation() async {
    if (state.bootstrapped) return LocationStatus.granted;
    final status = await locateAndCenter(zoom: 13);
    state = state.copyWith(bootstrapped: true);
    return status;
  }

  Future<LocationStatus> recenter() => locateAndCenter(zoom: 14);

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

final mapViewModelProvider = NotifierProvider<MapViewModel, MapViewState>(
  MapViewModel.new,
);
