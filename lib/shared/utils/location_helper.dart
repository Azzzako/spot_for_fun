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
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return LocationStatus.serviceOff;

      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }

      return switch (perm) {
        LocationPermission.always ||
        LocationPermission.whileInUse =>
          LocationStatus.granted,
        LocationPermission.deniedForever =>
          LocationStatus.deniedForever,
        LocationPermission.denied || LocationPermission.unableToDetermine =>
          LocationStatus.denied,
      };
    } catch (_) {
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
