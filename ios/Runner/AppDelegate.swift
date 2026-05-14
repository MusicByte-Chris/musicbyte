import Flutter
import UIKit
import AVFoundation

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Ensure the iOS audio session is configured for tone playback.
    // Without this, generated tones can be inaudible on iPhone/iPad (e.g. when the
    // Silent switch is enabled or when the default session category is used).
    do {
      let session = AVAudioSession.sharedInstance()
      try session.setCategory(.playback, mode: .default, options: [.mixWithOthers, .defaultToSpeaker])
      try session.setActive(true)
    } catch {
      // Don't crash if this fails; Flutter/audioplayers may still configure later.
      NSLog("AVAudioSession config failed: \(error)")
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
