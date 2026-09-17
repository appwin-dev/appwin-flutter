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

        case "bootstrapSession":
            let externalId = (call.arguments as? [String: Any])?["externalId"] as? String
            Task {
                do {
                    let token = try await AppwinCore.bootstrapSession(externalId: externalId)
                    await MainActor.run { result(token) }
                } catch {
                    await Self.fail(result, "bootstrap_failed", error)
                }
            }

        case "identify":
            guard let args = call.arguments as? [String: Any],
                let externalId = args["externalId"] as? String, !externalId.isEmpty
            else {
                result(FlutterError(code: "bad_args", message: "externalId manquant", details: nil))
                return
            }
            AppwinCore.identify(externalId: externalId)
            result(nil)

        case "clearIdentity":
            AppwinCore.clearIdentity()
            result(nil)

        case "signOut":
            Task {
                await AppwinCore.signOut()
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

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    /// Surfaces a native error to Flutter on the main thread.
    @MainActor
    private static func fail(_ result: @escaping FlutterResult, _ code: String, _ error: Error) {
        result(FlutterError(code: code, message: "\(error)", details: nil))
    }
}
