import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Register plugins against the AppDelegate's implicit engine so
    // method channels (shared_preferences, firebase_*, path_provider…)
    // resolve on the main FlutterEngine. The scene-delegate template
    // registers plugins only for *secondary* implicit engines via
    // `didInitializeImplicitFlutterEngine`, leaving the primary one
    // plugin-less on some iOS builds — the Dart Firebase init then
    // hangs because its method channel never answers.
    //
    // Firebase.configure() is intentionally NOT called here: the
    // Dart side runs `Firebase.initializeApp(options: ...)` from
    // FirebaseBootstrap, and calling it twice makes iOS throw
    // "FirebaseApp already configured" and crash on launch.
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
