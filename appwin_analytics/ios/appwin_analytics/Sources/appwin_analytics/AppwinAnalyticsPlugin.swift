import Flutter
import UIKit
@_spi(Appwin) import AppwinCore
@_spi(Appwin) import AppwinAnalytics

// Native modules are declared as `s.dependency` in the podspec (ADR-0020,
// Firebase/FlutterFire pattern). This file is the only glue; the
// implementations live in AppwinCore and AppwinAnalytics.
public class AppwinAnalyticsPlugin: NSObject, FlutterPlugin {
    private let registrar: FlutterPluginRegistrar

    private init(registrar: FlutterPluginRegistrar) {
        self.registrar = registrar
    }

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "appwin_analytics", binaryMessenger: registrar.messenger())
        let instance = AppwinAnalyticsPlugin(registrar: registrar)
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    @MainActor
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getPlatformVersion":
            result("iOS " + UIDevice.current.systemVersion)
        case "initialize":
            // Availability, not configuration: `AppwinCore.configure` is the
            // host app's job and runs through the appwin_core plugin. Only the
            // crash switch crosses: Dart's `inAppPackages` name Dart packages,
            // not the binary images `inAppModules` expects.
            let args = call.arguments as? [String: Any]
            let crashReporting = args?["crashReporting"] as? Bool ?? true
            let sessionReplay = args?["sessionReplay"] as? Bool ?? true
            AppwinAnalytics.setReplayRuntime("flutter")
            Task {
                let verdict = await AppwinAnalytics.initialize(
                    crashReporting: crashReporting, sessionReplay: sessionReplay)
                await MainActor.run { result(Self.encode(verdict)) }
            }
        case "replayMaskRules":
            let config = AppwinAnalytics.replayBridgeConfig
            // `captureFrames`: the Dart side renders the frames itself (see `setReplayFrame`).
            result(config.map {
                ["maskAllText": $0.maskAllText, "maskAllImages": $0.maskAllImages, "captureFrames": true]
            })
        case "setReplayMasks":
            let flat = ((call.arguments as? [String: Any])?["rects"] as? [NSNumber])?
                .map { CGFloat($0.doubleValue) } ?? []
            // Without the view, nothing is sent: the native side keeps the
            // whole surface masked until a set it can place arrives.
            if let view = registrar.viewController?.view, view.window != nil {
                AppwinAnalytics.setReplayBridgedMasks(Self.windowRects(flat, in: view))
            }
            result(nil)
        case "setReplayFrame":
            guard let args = call.arguments as? [String: Any],
                let pixels = args["rgba"] as? FlutterStandardTypedData,
                let width = (args["width"] as? NSNumber)?.intValue,
                let height = (args["height"] as? NSNumber)?.intValue
            else {
                result(FlutterError(code: "bad_args", message: "missing frame", details: nil))
                return
            }
            let flat = (args["rects"] as? [NSNumber])?.map { CGFloat($0.doubleValue) } ?? []
            if let view = registrar.viewController?.view, view.window != nil {
                AppwinAnalytics.setReplayBridgedFrame(
                    rgba: pixels.data, width: width, height: height,
                    masks: Self.windowRects(flat, in: view), surface: view)
            }
            result(nil)
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
        case "recordBridgedError":
            guard let args = call.arguments as? [String: Any],
                let type = args["type"] as? String
            else {
                result(FlutterError(code: "bad_args", message: "missing type", details: nil))
                return
            }
            let fatal = args["fatal"] as? Bool ?? false
            let message = args["message"] as? String
            let frames = args["frames"] as? [[String: Any]] ?? []
            // The report is fsync'ed before the call returns: off the main
            // thread, as on Android, so a burst of framework errors never
            // janks the UI.
            DispatchQueue.global(qos: .utility).async {
                AppwinAnalytics.recordBridgedError(
                    runtime: "flutter", fatal: fatal, type: type, message: message, frames: frames)
                DispatchQueue.main.async { result(nil) }
            }
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

    /// Flat `[left, top, right, bottom, ...]` logical pixels of the Flutter
    /// view to its window's points: logical pixels are points, only the
    /// view's offset applies.
    @MainActor
    private static func windowRects(_ flat: [CGFloat], in view: UIView) -> [CGRect] {
        var rects: [CGRect] = []
        var i = 0
        while i + 3 < flat.count {
            let rect = CGRect(
                x: flat[i], y: flat[i + 1], width: flat[i + 2] - flat[i], height: flat[i + 3] - flat[i + 1])
            rects.append(view.convert(rect, to: nil))
            i += 4
        }
        return rects
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
