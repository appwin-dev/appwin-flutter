import Flutter
import UIKit
import AppwinCore
import AppwinCommunity

// Native modules are declared as `s.dependency` in the podspec (ADR-0020,
// Firebase/FlutterFire pattern). This file is the only glue; the
// implementations live in AppwinCore and AppwinCommunity.

public class AppwinCommunityPlugin: NSObject, FlutterPlugin {

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "appwin_community",
            binaryMessenger: registrar.messenger()
        )
        let instance = AppwinCommunityPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)

        // The embeddable native view: it is what carries the feed full page in
        // a Flutter tab, unlike Support, which only presents modally.
        registrar.register(
            AppwinCommunityViewFactory(),
            withId: AppwinCommunityViewFactory.viewType
        )
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
                let verdict = await AppwinCommunity.initialize()
                await MainActor.run { result(Self.encode(verdict)) }
            }

        case "presentCommunity":
            AppwinCommunity.presentCommunity()
            result(nil)

        case "login":
            guard let args = call.arguments as? [String: Any],
                  let externalId = args["externalId"] as? String
            else {
                result(FlutterError(code: "bad_args", message: "externalId manquant", details: nil))
                return
            }
            Task {
                do {
                    try await AppwinCommunity.login(externalId: externalId)
                    print("[AppwinCommunity] login OK - externalId=\(externalId)")
                    await MainActor.run { result(nil) }
                } catch {
                    print("[AppwinCommunity] login FAILED: \(error)")
                    await Self.fail(result, "login_failed", error)
                }
            }

        case "logout":
            Task {
                await AppwinCommunity.logout()
                await MainActor.run { result(nil) }
            }

        case "setUser":
            let args = call.arguments as? [String: Any]
            Task {
                do {
                    let user = try await AppwinCommunity.setUser(
                        nickname: args?["nickname"] as? String,
                        avatarUrl: args?["avatarUrl"] as? String,
                        bio: args?["bio"] as? String
                    )
                    await MainActor.run { result(user.asDictionary) }
                } catch {
                    print("[AppwinCommunity] setUser FAILED: \(error)")
                    await Self.fail(result, "set_user_failed", error)
                }
            }

        case "unreadNotificationCount":
            Task {
                let count = await AppwinCommunity.unreadNotificationCount()
                await MainActor.run { result(count) }
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
