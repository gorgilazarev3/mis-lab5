import UIKit
import Flutter
import flutter_local_notifications
import flutter_config

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { (registry) in
    GeneratedPluginRegistrant.register(with: registry)}

    GeneratedPluginRegistrant.register(with: self)
    GMSServices.provideAPIKey(FlutterConfigPlugin.env(for: GOOGLE_MAPS_API_KEY))
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
