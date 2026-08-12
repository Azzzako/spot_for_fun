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
    this.accuracyMeters,
    this.tracking = false,
  });

  final LatLng? currentLocation;
  final bool hasRealLocation;
  final bool locating;
  final bool bootstrapped;
  final double? accuracyMeters;
  final bool tracking;

  const MapViewState.initial() : this();

  MapViewState copyWith({
    LatLng? currentLocation,
    bool? hasRealLocation,
    bool? locating,
    bool? bootstrapped,
    double? accuracyMeters,
    bool? tracking,
    bool clearLocation = false,
    bool clearAccuracy = false,
  }) {
    return MapViewState(
      currentLocation: clearLocation
          ? null
          : (currentLocation ?? this.currentLocation),
      hasRealLocation: hasRealLocation ?? this.hasRealLocation,
      locating: locating ?? this.locating,
      bootstrapped: bootstrapped ?? this.bootstrapped,
      accuracyMeters: clearAccuracy
          ? null
          : (accuracyMeters ?? this.accuracyMeters),
      tracking: tracking ?? this.tracking,
    );
  }
}

class MapViewModel extends Notifier<MapViewState> {
  StreamSubscription<Position>? _sub;

  @override
  MapViewState build() {
    ref.onDispose(_cancelSub);
    return const MapViewState.initial();
  }

  Future<LocationStatus> bootstrapLocation() async {
    if (state.bootstrapped) return LocationStatus.granted;
    final status = await locateAndCenter(zoom: 14);
    state = state.copyWith(bootstrapped: true);
    if (status == LocationStatus.granted) {
      await startTracking();
    }
    return status;
  }

  Future<LocationStatus> recenter() async {
    final status = await locateAndCenter(zoom: 15);
    if (status == LocationStatus.granted && !state.tracking) {
      await startTracking();
    }
    return status;
  }

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
          accuracyMeters: pos.accuracy,
        );
        return status;
      }
      state = state.copyWith(locating: false);
      return LocationStatus.serviceOff;
    }

    state = state.copyWith(locating: false);
    return status;
  }

  Future<void> startTracking() async {
    if (_sub != null) return;
    _sub = LocationHelper.positionStream().listen((pos) {
      state = state.copyWith(
        currentLocation: LatLng(pos.latitude, pos.longitude),
        hasRealLocation: true,
        accuracyMeters: pos.accuracy,
      );
    });
    state = state.copyWith(tracking: true);
  }

  Future<void> stopTracking() async {
    await _cancelSub();
    state = state.copyWith(tracking: false);
  }

  Future<void> _cancelSub() async {
    await _sub?.cancel();
    _sub = null;
  }
}

final mapViewModelProvider =
    NotifierProvider<MapViewModel, MapViewState>(MapViewModel.new);
