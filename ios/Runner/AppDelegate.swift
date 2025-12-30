import Flutter
import UIKit
import FirebaseCore

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Initialize Firebase FIRST, before Flutter plugins
    // Check if GoogleService-Info.plist exists
    if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
       FileManager.default.fileExists(atPath: path) {
      // Always configure Firebase if plist exists (FirebaseApp.configure() is safe to call multiple times)
      FirebaseApp.configure()
      print("✅ Firebase configured successfully from AppDelegate")
    } else {
      print("⚠️ GoogleService-Info.plist not found, skipping Firebase initialization")
    }
    
    // Register Flutter plugins AFTER Firebase initialization
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
