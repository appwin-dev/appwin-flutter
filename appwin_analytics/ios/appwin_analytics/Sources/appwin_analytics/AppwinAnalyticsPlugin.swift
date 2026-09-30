import Flutter
import UIKit
import AppwinCore
import AppwinAnalytics

// Native modules are declared as `s.dependency` in the podspec (ADR-0020,
// Firebase/FlutterFire pattern). This file is the only glue; the
// implementations live in AppwinCore and AppwinAnalytics.
public class AppwinAnalyticsPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "appwin_analytics", binaryMessenger: registrar.messenger())
        let instance = AppwinAnalyticsPlugin()
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
                let verdict = await AppwinAnalytics.initialize()
                await MainActor.run { result(Self.encode(verdict)) }
            }
        case "track":
            guard let args = call.arguments as? [String: Any],
                let name = args["name"] as? String
            else {
                result(FlutterError(code: "bad_args", message: "name manquant", details: nil))
                return
            }
            AppwinAnalytics.track(name, props: Self.parseProps(args["props"]))
            result(nil)
        case "screen":
            guard let args = call.arguments as? [String: Any],
                let name = args["name"] as? String
            else {
                result(FlutterError(code: "bad_args", message: "name manquant", details: nil))
                return
            }
            AppwinAnalytics.screen(name)
            result(nil)
        case "flush":
            AppwinAnalytics.flush()
            result(nil)
        case "setConsent":
            let raw = (call.arguments as? [String: Any])?["consent"] as? String
            AppwinAnalytics.setConsent(Self.parseConsent(raw))
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    /// Method-channel props to the SDK's typed values. Numbers cross the
    /// channel as NSNumber: booleans are told apart via the ObjC type
    /// encoding, ints stay ints, everything decimal becomes a double.
    private static func parseProps(_ raw: Any?) -> [String: AnalyticsValue]? {
        guard let dict = raw as? [String: Any], !dict.isEmpty else { return nil }
        var out: [String: AnalyticsValue] = [:]
        for (key, value) in dict {
            switch value {
            case let number as NSNumber:
                if CFGetTypeID(number) == CFBooleanGetTypeID() {
                    out[key] = .bool(number.boolValue)
                } else if CFNumberIsFloatType(number) {
                    out[key] = .double(number.doubleValue)
                } else {
                    out[key] = .int(number.intValue)
                }
            case let string as String:
                out[key] = .string(string)
            default:
                out[key] = AnalyticsValue.string(String(describing: value))
            }
        }
        return out
    }

    private static func parseConsent(_ raw: String?) -> AnalyticsConsent {
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
