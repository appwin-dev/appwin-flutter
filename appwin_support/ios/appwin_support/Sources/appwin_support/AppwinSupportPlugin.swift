import Flutter
import UIKit
import AppwinCore
import AppwinSupport

// Native modules are declared as `s.dependency` in the podspec (ADR-0020,
// Firebase/FlutterFire pattern). This file is the only glue; the
// implementations live in AppwinCore and AppwinSupport.
//
// Nothing is reimplemented here, not even a "simple" HTTP call. This glue used
// to hit the in-app endpoints by hand, and the copy drifted from the original
// unnoticed while the Android bridge called the real modules. A bridge that
// talks to the network is no longer a bridge.

public class AppwinSupportPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "appwin_support", binaryMessenger: registrar.messenger())
        let instance = AppwinSupportPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

@MainActor
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getPlatformVersion":
            result("iOS " + UIDevice.current.systemVersion)
        case "presentMessenger":
            DispatchQueue.main.async {
                AppwinSupport.presentMessenger()
                result(nil)
            }
        case "presentConversation":
            guard let args = call.arguments as? [String: Any],
                let conversationId = args["conversationId"] as? String,
                !conversationId.isEmpty
            else {
                result(
                    FlutterError(code: "bad_args", message: "conversationId missing", details: nil))
                return
            }
            AppwinSupport.presentConversation(id: conversationId)
            result(nil)
        case "initialize":
            // Availability, not configuration: `AppwinCore.configure` is the
            // host app's job and runs through the appwin_core plugin.
            Task {
                let verdict = await AppwinSupport.initialize()
                await MainActor.run { result(Self.encode(verdict)) }
            }

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    /// Surfaces a native error to Flutter on the main thread.
    @MainActor
    private static func fail(_ result: @escaping FlutterResult, _ code: String, _ error: Error) {
        result(FlutterError(code: code, message: "\(error)", details: nil))
    }

    /// Maps the native result onto what the Dart side parses.
    ///
    /// A dictionary rather than a raw string: the reason travels with the
    /// status, and the two must not drift apart across the channel.
    static func encode(_ result: AppwinInitResult) -> [String: Any] {
        switch result {
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
