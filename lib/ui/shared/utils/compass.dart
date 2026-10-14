import 'package:flutter/services.dart';

/// Device heading in degrees (0 = north, clockwise), streamed by native
/// code in the app itself: MainActivity.kt (Android rotation-vector
/// sensor) and AppDelegate.swift (iOS CoreLocation, already calibrated).
/// Replaces flutter_compass, the only plugin that forced CocoaPods on iOS.
class Compass {
  Compass._();

  static const _channel = EventChannel('spot4fun/heading');

  /// Emits nothing on devices without a compass. Listening starts the
  /// sensor; cancelling the subscription stops it.
  static Stream<double> get headings => _channel
      .receiveBroadcastStream()
      .map((event) => (event as num).toDouble());
}
