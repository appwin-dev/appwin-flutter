import Flutter
import UIKit
import AppwinCore
import AppwinCommunity

// Native modules are declared as `s.dependency` in the podspec (ADR-0020,
// Firebase/FlutterFire pattern). This file is the only glue; the
// implementations live in AppwinCore and AppwinCommunity.

public class AppwinCommunityPlugin: NSObject, FlutterPlugin {
    private let channel: FlutterMethodChannel

    init(channel: FlutterMethodChannel) {
        self.channel = channel
    }

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "appwin_community",
            binaryMessenger: registrar.messenger()
        )
        let instance = AppwinCommunityPlugin(channel: channel)
        registrar.addMethodCallDelegate(instance, channel: channel)

        FlutterEventChannel(name: "appwin_community/events", binaryMessenger: registrar.messenger())
            .setStreamHandler(AsyncStreamHandler({ AppwinCommunity.events }, encode: Self.encode))
        FlutterEventChannel(name: "appwin_community/unread_count", binaryMessenger: registrar.messenger())
            .setStreamHandler(AsyncStreamHandler({ AppwinCommunity.unreadNotificationCountUpdates }, encode: { $0 }))

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

        case "openPost":
            guard let args = call.arguments as? [String: Any],
                let postId = args["postId"] as? String, !postId.isEmpty
            else {
                result(FlutterError(code: "bad_args", message: "postId missing", details: nil))
                return
            }
            AppwinCommunity.openPost(postId, commentId: args["commentId"] as? String)
            result(nil)

        case "setHostCallbacks":
            let args = call.arguments as? [String: Any]
            setHostCallbacks(
                notificationTap: args?["notificationTap"] as? Bool ?? false,
                editProfile: args?["editProfile"] as? Bool ?? false
            )
            result(nil)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    /// Dart owns the handlers; native only learns whether each one exists, and
    /// calls back over the channel.
    @MainActor
    private func setHostCallbacks(notificationTap: Bool, editProfile: Bool) {
        let channel = self.channel
        if notificationTap {
            AppwinCommunity.onNotificationTap = { target in
                Self.forwardNotificationTap(target, over: channel)
            }
        } else {
            AppwinCommunity.onNotificationTap = nil
        }
        if editProfile {
            AppwinCommunity.onEditProfile = {
                channel.invokeMethod("onEditProfile", arguments: nil)
            }
        } else {
            AppwinCommunity.onEditProfile = nil
        }
    }

    @MainActor
    private static func forwardNotificationTap(
        _ target: AppwinCommunityPostTarget,
        over channel: FlutterMethodChannel
    ) {
        var arguments: [String: Any] = ["postId": target.postId]
        arguments["commentId"] = target.commentId
        channel.invokeMethod("onNotificationTap", arguments: arguments) { handled in
            // Dart answers `false`, or not at all after a hot restart, when no
            // handler is left: the tap must still open.
            guard (handled as? Bool) != true else { return }
            Task { @MainActor in
                AppwinCommunity.openPost(target.postId, commentId: target.commentId)
            }
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
    static func encode(_ event: AppwinCommunityEvent) -> Any {
        switch event {
        case .postCreated(let postId):
            return ["type": "postCreated", "postId": postId]
        case .commentCreated(let commentId, let postId):
            return ["type": "commentCreated", "commentId": commentId, "postId": postId]
        case .replyCreated(let replyId, let commentId, let postId):
            return ["type": "replyCreated", "replyId": replyId, "commentId": commentId, "postId": postId]
        case .reactionModified(let postId, let commentId, let reaction):
            var map: [String: Any] = ["type": "reactionModified", "postId": postId]
            map["commentId"] = commentId
            map["reaction"] = reaction
            return map
        case .profileUpdated(let profileId):
            return ["type": "profileUpdated", "profileId": profileId]
        }
    }

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

/// Pipes a native `AsyncStream` into an event channel, one native
/// subscription per Dart listen.
final class AsyncStreamHandler: NSObject, FlutterStreamHandler {
    private let subscribe: (@escaping FlutterEventSink) -> Task<Void, Never>
    private var task: Task<Void, Never>?

    init<Element>(_ makeStream: @escaping @MainActor () -> AsyncStream<Element>, encode: @escaping (Element) -> Any) {
        subscribe = { sink in
            Task { @MainActor in
                for await value in makeStream() { sink(encode(value)) }
            }
        }
        super.init()
    }

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        task?.cancel()
        task = subscribe(events)
        return nil
    }

    // Cancelling the task ends its `for await`, which releases the native
    // subscription through the stream's termination handler.
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        task?.cancel()
        task = nil
        return nil
    }
}
