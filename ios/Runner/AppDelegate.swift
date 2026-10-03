import Flutter
import UIKit
import FirebaseCore

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Configure Firebase in native code (reads GoogleService-Info.plist
    // from the main bundle) so the SDK is ready before any Dart-side
    // plugin method channel call. Without this, Firestore / Messaging /
    // Analytics init race against the first Dart call and the app
    // boots to a blank screen when the race loses.
    FirebaseApp.configure()
    // Register plugins against the AppDelegate's implicit engine so
    // method channels (shared_preferences, path_provider, firebase_*
    // etc.) resolve on the main FlutterEngine. The scene-delegate
    // template only registers plugins for *secondary* implicit engines
    // via `didInitializeImplicitFlutterEngine`, leaving the main one
    // plugin-less on some iOS builds.
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
