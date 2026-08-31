import Flutter
import UIKit
import AppwinCore
import AppwinNotifications
import AppwinSupport

// Native modules are declared as `s.dependency` in the podspec (ADR-0020,
// Firebase/FlutterFire pattern). This file is the only glue; the
// implementations live in AppwinCore, AppwinSupport and AppwinNotifications.
//
// Nothing is reimplemented here, not even a "simple" HTTP call. This glue used
// to hit the in-app endpoints by hand, and the copy drifted from the original
// unnoticed while the Android bridge called the real modules. A bridge that
// talks to the network is no longer a bridge.

public class AppwinSupportPlugin: NSObject, FlutterPlugin {
    /// Avoids re-firing `app_open` on every in-app poll within one foreground.
    private static var didTrackAppOpenThisForeground = false
    private static var lifecycleObserversRegistered = false

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "appwin_support", binaryMessenger: registrar.messenger())
        let instance = AppwinSupportPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        Self.registerLifecycleObserversIfNeeded()
    }

    private static func registerLifecycleObserversIfNeeded() {
        guard !lifecycleObserversRegistered else { return }
        lifecycleObserversRegistered = true
        NotificationCenter.default.addObserver(
            forName: UIApplication.willResignActiveNotification,
            object: nil,
            queue: .main
        ) { _ in
            didTrackAppOpenThisForeground = false
        }
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
        case "initialize":
            guard let args = call.arguments as? [String: Any],
                let appId = args["appId"] as? String
            else {
                result(FlutterError(code: "bad_args", message: "appId manquant", details: nil))
                return
            }
            // `baseUrl` is for development, pointing at localhost. We call
            // `AppwinCore.configure` directly to pass it, since
            // `AppwinSupport.initialize` does not expose the parameter yet.
            let baseUrl = args["baseUrl"] as? String
            AppwinCore.configure(projectAppId: appId, baseUrl: baseUrl)
            print(
                "[AppwinPush] configure OK - projectAppId=\(appId) deviceId=\(AppwinCore.deviceId ?? "nil") baseUrl=\(AppwinCore.baseUrl)"
            )
            Task {
                do {
                    _ = try await AppwinCore.bootstrapSession()
                    let bearerPresent = AuthSession.currentToken() != nil
                    print(
                        "[AppwinPush] bootstrapSession OK - bearer present=\(bearerPresent) sessionId=\(AuthSession.currentSessionId ?? "nil")"
                    )
                    await MainActor.run { result(nil) }
                } catch {
                    print("[AppwinPush] bootstrapSession FAILED: \(error)")
                    await Self.fail(result, "bootstrap_failed", error)
                }
            }

        case "loginUnidentifiedUser":
            Task {
                do {
                    let customer = try await AppwinSupport.loginUnidentifiedUser()
                    print(
                        "[AppwinPush] identify OK - customerId=\(customer.id) externalId=\(customer.externalId ?? "nil")"
                    )
                    await MainActor.run { result(nil) }
                } catch {
                    print("[AppwinPush] identify FAILED: \(error)")
                    await Self.fail(result, "login_failed", error)
                }
            }
        case "loginIdentifiedUser":
            guard let args = call.arguments as? [String: Any],
                let externalId = args["externalId"] as? String
            else {
                result(
                    FlutterError(code: "bad_args", message: "externalId manquant", details: nil))
                return
            }
            Task {
                do {
                    let customer = try await AppwinSupport.loginIdentifiedUser(externalId: externalId)
                    print(
                        "[AppwinPush] identify OK - customerId=\(customer.id) externalId=\(customer.externalId ?? "nil")"
                    )
                    await MainActor.run { result(nil) }
                } catch {
                    print("[AppwinPush] identify FAILED: \(error)")
                    await Self.fail(result, "login_failed", error)
                }
            }
        case "updateUser":
            let args = call.arguments as? [String: Any]
            Task {
                do {
                    _ = try await AppwinSupport.updateUser(attributes: Self.parseAttributes(args))
                    await MainActor.run { result(nil) }
                } catch {
                    await Self.fail(result, "update_failed", error)
                }
            }
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
                    // Support route rather than Notifications: it writes to
                    // the same table without requiring the Notifications
                    // product on the app id. Same choice as the Android bridge.
                    try await AppwinSupport.registerPushToken(
                        token,
                        platform: platform,
                        pushOptIn: pushOptIn
                    )
                    await MainActor.run { result(nil) }
                } catch {
                    await Self.fail(result, "register_push_token_failed", error)
                }
            }
        case "fetchPendingInAppMessages":
            Task {
                do {
                    // App-open automations only create a delivery after the
                    // event, so it is sent before the read; otherwise the
                    // message it triggers would only arrive on the next call.
                    // Once per foreground transition, not once per call: a tab
                    // re-reading its messages must not replay the app opening.
                    if !Self.didTrackAppOpenThisForeground {
                        Self.didTrackAppOpenThisForeground = true
                        try? await AppwinNotifications.trackEvent(.appOpen)
                    }
                    let messages = try await AppwinNotifications.fetchPendingMessages()
                    await MainActor.run { result(messages.map(Self.serialize)) }
                } catch {
                    await Self.fail(result, "fetch_in_app_failed", error)
                }
            }
        case "trackInAppDelivery":
            guard let args = call.arguments as? [String: Any],
                let deliveryId = args["deliveryId"] as? String,
                let raw = args["event"] as? String,
                let event = TrackEvent(rawValue: raw)
            else {
                result(FlutterError(code: "bad_args", message: "deliveryId/event manquant", details: nil))
                return
            }
            Task {
                do {
                    try await AppwinNotifications.track(deliveryId: deliveryId, event: event)
                    await MainActor.run { result(nil) }
                } catch {
                    await Self.fail(result, "track_in_app_failed", error)
                }
            }
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    /// Method-channel map, read by `AppwinInAppMessage`.
    ///
    /// The only place this glue knows a message's shape: the model itself comes
    /// from AppwinNotifications, not from a DTO copied in here.
    private static func serialize(_ message: InAppMessage) -> [String: Any] {
        [
            "id": message.id,
            "campaignId": message.campaignId,
            "deliveryId": message.deliveryId,
            "channel": message.channel,
            "format": message.format,
            "content": [
                "title": message.content.title as Any,
                "body": message.content.body as Any,
                "imageUrl": message.content.imageUrl as Any,
                "deeplink": message.content.deeplink as Any,
            ],
        ]
    }

    /// Surfaces a native error to Flutter on the main thread.
    @MainActor
    private static func fail(_ result: @escaping FlutterResult, _ code: String, _ error: Error) {
        result(FlutterError(code: code, message: "\(error)", details: nil))
    }

    /// Rebuilds the native `AppwinSupportUserAttributes` from the `attributes`
    /// map sent by the Dart method channel.
    private static func parseAttributes(_ args: [String: Any]?) -> AppwinSupportUserAttributes {
        let a = (args?["attributes"] as? [String: Any]) ?? [:]
        return AppwinSupportUserAttributes(
            email: a["email"] as? String,
            name: a["name"] as? String,
            avatarUrl: a["avatarUrl"] as? String,
            language: a["language"] as? String,
            timezone: a["timezone"] as? String,
            location: a["location"] as? String
        )
    }
}
