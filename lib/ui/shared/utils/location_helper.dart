import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

enum LocationStatus {
  granted,
  serviceOff,
  denied,
  deniedForever,
  error,
}

class LocationHelper {
  LocationHelper._();

  static const LatLng neutralCenter = LatLng(0, 0);
  static const double neutralZoom = 2;

  static Future<LocationStatus> ensurePermission() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }

      final granted = perm == LocationPermission.always ||
          perm == LocationPermission.whileInUse;

      if (!granted) {
        return switch (perm) {
          LocationPermission.deniedForever =>
            LocationStatus.deniedForever,
          _ => LocationStatus.denied,
        };
      }

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return LocationStatus.serviceOff;

      return LocationStatus.granted;
    } catch (e) {
      debugPrint('[LocationHelper] ensurePermission error: $e');
      return LocationStatus.error;
    }
  }

  static Future<Position?> currentPosition({
    Duration timeout = const Duration(seconds: 8),
  }) async {
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: timeout,
        ),
      );
    } catch (_) {
      return null;
    }
  }

  static Future<LatLng> currentLatLng({
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final pos = await currentPosition(timeout: timeout);
    return pos == null ? neutralCenter : LatLng(pos.latitude, pos.longitude);
  }

  static Stream<Position> positionStream({
    int distanceFilter = 10,
    LocationAccuracy accuracy = LocationAccuracy.high,
  }) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
      ),
    );
  }

  static Future<bool> openAppSettings() async {
    try {
      return await Geolocator.openAppSettings();
    } catch (_) {
      return false;
    }
  }

  static Future<bool> openLocationSettings() async {
    try {
      return await Geolocator.openLocationSettings();
    } catch (_) {
      return false;
    }
  }
}
