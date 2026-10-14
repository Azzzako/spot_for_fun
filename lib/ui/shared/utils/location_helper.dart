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

  /// Where the map opens without a GPS fix: Mexico City, the app's home
  /// scene (was 0,0 — the middle of the ocean).
  static const LatLng neutralCenter = LatLng(19.4326, -99.1332);
  static const double neutralZoom = 11;

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

  /// Continuous fixes while the app is in the foreground. A new fix
  /// arrives after moving [distanceFilterMeters]; the caller cancels the
  /// subscription to stop the GPS.
  static Stream<Position> positionStream({int distanceFilterMeters = 8}) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilterMeters,
      ),
    );
  }

  static Future<LatLng> currentLatLng({
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final pos = await currentPosition(timeout: timeout);
    return pos == null ? neutralCenter : LatLng(pos.latitude, pos.longitude);
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
