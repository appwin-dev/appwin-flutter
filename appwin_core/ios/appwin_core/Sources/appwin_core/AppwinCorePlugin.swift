import Flutter
import UIKit
import AppwinCore

/// Glue Dart↔Swift du socle.
///
/// The native module is declared as `s.dependency` in the podspec and as
/// `.package` in `Package.swift` (ADR-0020, Firebase/FlutterFire pattern): this
/// file only routes calls, and the whole implementation lives in AppwinCore.
public class AppwinCorePlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "appwin_core", binaryMessenger: registrar.messenger())
        registrar.addMethodCallDelegate(AppwinCorePlugin(), channel: channel)
        FlutterEventChannel(name: "appwin_core/availability", binaryMessenger: registrar.messenger())
            .setStreamHandler(AvailabilityStreamHandler())
    }

    @MainActor
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getPlatformVersion":
            result("iOS " + UIDevice.current.systemVersion)

        case "configure":
            guard let args = call.arguments as? [String: Any],
                let appId = args["appId"] as? String
            else {
                result(FlutterError(code: "bad_args", message: "appId manquant", details: nil))
                return
            }
            // `configure` is synchronous natively: it prepares the identity and
            // the client, then opens the session in the background. We return
            // immediately rather than waiting for the network - an offline app
            // must start as fast as any other.
            AppwinCore.configure(
                projectAppId: appId,
                baseUrl: args["baseUrl"] as? String,
                realtimeBaseUrl: args["realtimeBaseUrl"] as? String
            )
            result(nil)

        case "identify":
            guard let args = call.arguments as? [String: Any],
                let externalId = args["externalId"] as? String, !externalId.isEmpty
            else {
                result(FlutterError(code: "bad_args", message: "externalId missing", details: nil))
                return
            }
            let attributes = (args["attributes"] as? [String: Any]).map(Self.attributes)
            Task {
                do {
                    try await AppwinCore.identify(externalId: externalId, attributes: attributes)
                    await MainActor.run { result(nil) }
                } catch {
                    await Self.fail(result, "identify_failed", error)
                }
            }

        case "updateUser":
            let raw = (call.arguments as? [String: Any])?["attributes"] as? [String: Any] ?? [:]
            Task {
                do {
                    try await AppwinCore.updateUser(Self.attributes(raw))
                    await MainActor.run { result(nil) }
                } catch {
                    await Self.fail(result, "update_user_failed", error)
                }
            }

        case "logout":
            Task {
                await AppwinCore.logout()
                await MainActor.run { result(nil) }
            }

        case "track":
            guard let args = call.arguments as? [String: Any],
                let name = args["name"] as? String
            else {
                result(FlutterError(code: "bad_args", message: "name manquant", details: nil))
                return
            }
            AppwinCore.track(name, props: Self.parseProps(args["props"]))
            result(nil)

        case "setConsent":
            guard let args = call.arguments as? [String: Any],
                let raw = args["state"] as? String,
                let state = ConsentState(rawValue: raw)
            else {
                result(FlutterError(code: "bad_args", message: "state manquant", details: nil))
                return
            }
            var purpose: ConsentPurpose?
            if let rawPurpose = args["purpose"] as? String {
                guard let parsed = ConsentPurpose(rawValue: rawPurpose) else {
                    result(FlutterError(code: "bad_args", message: "purpose inconnue", details: nil))
                    return
                }
                purpose = parsed
            }
            AppwinCore.setConsent(state, for: purpose)
            result(nil)

        case "deviceId":
            result(AppwinCore.deviceId)

        case "hasRegisteredPushToken":
            result(AppwinCore.hasRegisteredPushToken)

        case "registerPushToken":
            guard let args = call.arguments as? [String: Any],
                let token = args["token"] as? String,
                !token.isEmpty
            else {
                result(FlutterError(code: "bad_args", message: "token manquant", details: nil))
                return
            }
            let platform = args["platform"] as? String ?? "ios"
            let pushOptIn = args["pushOptIn"] as? Bool ?? true
            Task {
                do {
                    try await AppwinCore.registerPushToken(
                        token,
                        platform: platform,
                        pushOptIn: pushOptIn
                    )
                    await MainActor.run { result(nil) }
                } catch {
                    await Self.fail(result, "register_push_failed", error)
                }
            }

        case "isAppwinPush":
            result(AppwinPush.isAppwinPush(Self.pushData(call)))

        case "handlePushTap":
            result(AppwinPush.handleTap(Self.pushData(call)))

        case "handlePushForeground":
            let args = call.arguments as? [String: Any]
            result(AppwinPush.handleForeground(
                Self.pushData(call),
                title: args?["title"] as? String,
                body: args?["body"] as? String
            ))

        case "handlePushMessage":
            let data = Self.pushData(call)
            Task {
                let consumed = await AppwinPush.handleMessage(data)
                await MainActor.run { result(consumed) }
            }

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    /// Dart omits null fields, so an absent key stays `nil` and is left
    /// untouched server-side.
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

    private static func attributes(_ raw: [String: Any]) -> AppwinUserAttributes {
        AppwinUserAttributes(
            email: raw["email"] as? String,
            name: raw["name"] as? String,
            avatarUrl: raw["avatarUrl"] as? String,
            language: raw["language"] as? String,
            timezone: raw["timezone"] as? String,
            location: raw["location"] as? String,
            plan: raw["plan"] as? String,
            customAttributes: (raw["customAttributes"] as? [String: Any])?
                .compactMapValues { $0 as? String }
        )
    }

    private static func pushData(_ call: FlutterMethodCall) -> [AnyHashable: Any] {
        let data = (call.arguments as? [String: Any])?["data"] as? [String: Any] ?? [:]
        return data.reduce(into: [:]) { $0[$1.key] = $1.value }
    }

    /// Maps a verdict onto what `AppwinInitResult.fromMap` parses in Dart.
    static func encode(_ result: AppwinInitResult, pause: AppwinPause? = nil) -> [String: Any] {
        var event: [String: Any]
        switch result {
        case .ready:
            event = ["status": "ready"]
        case .notConfigured:
            event = ["status": "notConfigured"]
        case .unknown:
            event = ["status": "unknown"]
        case .unavailable(let reason):
            event = ["status": "unavailable", "reason": reason.rawValue]
        }
        if let pause { event["pause"] = encode(pause) }
        return event
    }

    /// The pause as the Dart side reads it; text as served, the empty string included.
    static func encode(_ pause: AppwinPause) -> [String: String] {
        ["since": pause.since, "title": pause.title, "message": pause.message]
    }

    /// Surfaces a native error to Flutter on the main thread.
    @MainActor
    private static func fail(_ result: @escaping FlutterResult, _ code: String, _ error: Error) {
        result(FlutterError(code: code, message: "\(error)", details: nil))
    }
}

/// Backs the `appwin_core/availability` event channel.
///
/// Dart holds one subscription for every product it watches (an event channel
/// carries only one), so each event says which product it is about.
final class AvailabilityStreamHandler: NSObject, FlutterStreamHandler {
    private var tasks: [Task<Void, Never>] = []

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        cancelAll()
        let keys = (arguments as? [String: Any])?["products"] as? [String] ?? []
        tasks = keys.compactMap(AppwinProduct.init(rawValue:)).map { product in
            Task { @MainActor in
                for await result in AppwinCore.availabilityUpdates(of: product) {
                    // The pause is read after each verdict: the two streams are separate.
                    let pause = await AppwinCore.pause(of: product)
                    var event = AppwinCorePlugin.encode(result, pause: pause)
                    event["product"] = product.rawValue
                    events(event)
                }
            }
        }
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        cancelAll()
        return nil
    }

    // Cancelling the task ends its `for await`, which releases the native
    // subscription through the stream's termination handler.
    private func cancelAll() {
        tasks.forEach { $0.cancel() }
        tasks = []
    }
}
