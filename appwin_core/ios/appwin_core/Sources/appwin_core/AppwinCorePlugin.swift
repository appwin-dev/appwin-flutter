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
    private static func attributes(_ raw: [String: Any]) -> AppwinUserAttributes {
        AppwinUserAttributes(
            email: raw["email"] as? String,
            name: raw["name"] as? String,
            avatarUrl: raw["avatarUrl"] as? String,
            language: raw["language"] as? String,
            timezone: raw["timezone"] as? String,
            location: raw["location"] as? String,
            plan: raw["plan"] as? String
        )
    }

    private static func pushData(_ call: FlutterMethodCall) -> [AnyHashable: Any] {
        let data = (call.arguments as? [String: Any])?["data"] as? [String: Any] ?? [:]
        return data.reduce(into: [:]) { $0[$1.key] = $1.value }
    }

    /// Surfaces a native error to Flutter on the main thread.
    @MainActor
    private static func fail(_ result: @escaping FlutterResult, _ code: String, _ error: Error) {
        result(FlutterError(code: code, message: "\(error)", details: nil))
    }
}
