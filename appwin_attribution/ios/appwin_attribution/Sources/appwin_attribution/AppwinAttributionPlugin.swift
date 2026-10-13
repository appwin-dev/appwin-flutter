import Flutter
import UIKit
import AppwinCore
import AppwinAttribution

// Native modules are declared as `s.dependency` in the podspec (ADR-0020,
// Firebase/FlutterFire pattern). This file is the only glue; the
// implementations live in AppwinCore and AppwinAttribution.
public class AppwinAttributionPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "appwin_attribution", binaryMessenger: registrar.messenger())
        let instance = AppwinAttributionPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    @MainActor
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getPlatformVersion":
            result("iOS " + UIDevice.current.systemVersion)
        case "initialize":
            // Availability, not configuration: `AppwinCore.configure` is the
            // host app's job and runs through the appwin_core plugin.
            Task {
                let verdict = await AppwinAttribution.initialize()
                await MainActor.run { result(Self.encode(verdict)) }
            }
        case "setAdvertisingConsent":
            let raw = (call.arguments as? [String: Any])?["consent"] as? String
            AppwinAttribution.setAdvertisingConsent(Self.parseConsent(raw))
            result(nil)
        case "requestTrackingAuthorization":
            Task {
                let granted = await AppwinAttribution.requestTrackingAuthorization()
                await MainActor.run { result(granted) }
            }
        case "setAdSignalsDebugMode":
            let enabled = (call.arguments as? [String: Any])?["enabled"] as? Bool ?? false
            AppwinAttribution.setAdSignalsDebugMode(enabled)
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private static func parseConsent(_ raw: String?) -> AdvertisingConsent {
        switch raw {
        case "granted": return .granted
        case "denied": return .denied
        default: return .unknown
        }
    }

    /// Maps the native result onto what the Dart side parses. Same shape
    /// as every other product plugin: status + optional reason.
    private static func encode(_ verdict: AppwinInitResult) -> [String: Any] {
        switch verdict {
        case .ready:
            return ["status": "ready"]
        case .notConfigured:
            return ["status": "notConfigured"]
        case .unknown:
            return ["status": "unknown"]
        case .unavailable(let reason):
            return ["status": "unavailable", "reason": reason.rawValue]
        }
    }
}
