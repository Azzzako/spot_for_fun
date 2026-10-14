import CoreLocation
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "HeadingStreamPlugin") {
      HeadingStreamPlugin.register(with: registrar)
    }
  }
}

/// Streams the compass heading in degrees (0 = north, clockwise) to
/// lib/ui/shared/utils/compass.dart. CoreLocation's heading is already
/// calibrated by iOS; true north when available, magnetic otherwise.
/// Heading updates only run while Dart is listening.
final class HeadingStreamPlugin: NSObject, FlutterPlugin, FlutterStreamHandler,
  CLLocationManagerDelegate
{
  private let manager = CLLocationManager()
  private var sink: FlutterEventSink?

  static func register(with registrar: FlutterPluginRegistrar) {
    let instance = HeadingStreamPlugin()
    let channel = FlutterEventChannel(
      name: "spot4fun/heading", binaryMessenger: registrar.messenger())
    channel.setStreamHandler(instance)
  }

  override init() {
    super.init()
    manager.delegate = self
    manager.headingFilter = 1
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink)
    -> FlutterError?
  {
    // No compass (e.g. the simulator): emit nothing, the map shows the dot.
    guard CLLocationManager.headingAvailable() else { return nil }
    sink = events
    manager.startUpdatingHeading()
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    manager.stopUpdatingHeading()
    sink = nil
    return nil
  }

  func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
    let heading = newHeading.trueHeading >= 0 ? newHeading.trueHeading : newHeading.magneticHeading
    sink?(heading)
  }
}
