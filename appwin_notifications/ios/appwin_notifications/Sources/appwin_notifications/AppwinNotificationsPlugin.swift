import Flutter
import UIKit
import AppwinCore
import AppwinNotifications

/**
 Dart-to-Swift glue for the Notifications product.

 Mirrors `AppwinNotificationsPlugin.kt`: same method names, same arguments,
 same error codes. A divergence between the two only shows on one platform,
 which is the worst way to find it.
 */
public class AppwinNotificationsPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "appwin_notifications",
      binaryMessenger: registrar.messenger()
    )
    registrar.addMethodCallDelegate(AppwinNotificationsPlugin(), channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)

    case "initialize":
      // Availability, not configuration: `AppwinCore.configure` is the host
      // app's job and runs through the appwin_core plugin.
      Task {
        let verdict = await AppwinNotifications.initialize()
        await MainActor.run { result(Self.encode(verdict)) }
      }

    case "registerPushToken":
      guard let args = call.arguments as? [String: Any],
            let token = args["token"] as? String
      else {
        result(Self.badArgs("token")); return
      }
      let optIn = args["pushOptIn"] as? Bool ?? true
      Task {
        do {
          try await AppwinCore.registerPushToken(token, pushOptIn: optIn)
          await MainActor.run { result(nil) }
        } catch {
          await Self.fail(result, "register_failed", error)
        }
      }

    case "trackEvent":
      guard let args = call.arguments as? [String: Any],
            let raw = args["event"] as? String,
            let event = AutomationEvent(rawValue: raw)
      else {
        result(Self.badArgs("event")); return
      }
      let name = args["eventName"] as? String
      let properties = args["properties"] as? [String: String]
      Task {
        do {
          try await AppwinNotifications.trackEvent(event, eventName: name, properties: properties)
          await MainActor.run { result(nil) }
        } catch {
          await Self.fail(result, "track_event_failed", error)
        }
      }

    case "fetchPendingMessages":
      Task {
        do {
          let messages = try await AppwinNotifications.fetchPendingMessages()
          await MainActor.run { result(messages.map(Self.encode)) }
        } catch {
          await Self.fail(result, "fetch_failed", error)
        }
      }

    case "track":
      guard let args = call.arguments as? [String: Any],
            let deliveryId = args["deliveryId"] as? String,
            let raw = args["event"] as? String,
            let event = TrackEvent(rawValue: raw)
      else {
        result(Self.badArgs("deliveryId/event")); return
      }
      let buttonIndex = args["buttonIndex"] as? Int
      Task {
        do {
          try await AppwinNotifications.track(
            deliveryId: deliveryId,
            event: event,
            buttonIndex: buttonIndex
          )
          await MainActor.run { result(nil) }
        } catch {
          await Self.fail(result, "track_failed", error)
        }
      }

    case "syncOnAppOpen":
      Task {
        do {
          let messages = try await AppwinNotifications.syncOnAppOpen()
          await MainActor.run { result(messages.map(Self.encode)) }
        } catch {
          await Self.fail(result, "sync_failed", error)
        }
      }

    case "start":
      let requestPush = (call.arguments as? [String: Any])?["requestPushPermission"] as? Bool ?? true
      Task {
        await AppwinNotifications.start(requestPushPermission: requestPush)
        await MainActor.run { result(nil) }
      }

    case "stop":
      Task { @MainActor in
        AppwinNotifications.stop()
        result(nil)
      }

    case "presentPendingMessages":
      Task {
        do {
          try await AppwinNotifications.presentPendingMessages()
          await MainActor.run { result(nil) }
        } catch {
          await Self.fail(result, "present_failed", error)
        }
      }

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  // MARK: - Encoding

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

  static func encode(_ message: InAppMessage) -> [String: Any] {
    var content: [String: Any] = [:]
    if let title = message.content.title { content["title"] = title }
    if let body = message.content.body { content["body"] = body }
    if let imageUrl = message.content.imageUrl { content["imageUrl"] = imageUrl }
    if let deeplink = message.content.deeplink { content["deeplink"] = deeplink }
    if let buttons = message.content.buttons {
      content["buttons"] = buttons.map { button in
        var map: [String: Any] = ["label": button.label, "action": button.action.rawValue]
        if let url = button.url { map["url"] = url }
        return map
      }
    }
    return [
      "id": message.id,
      "campaignId": message.campaignId,
      "deliveryId": message.deliveryId,
      "channel": message.channel.rawValue,
      "format": message.format.rawValue,
      "content": content,
    ]
  }

  static func badArgs(_ missing: String) -> FlutterError {
    FlutterError(code: "bad_args", message: "\(missing) manquant", details: nil)
  }

  @MainActor
  static func fail(_ result: @escaping FlutterResult, _ code: String, _ error: Error) {
    result(FlutterError(code: code, message: error.localizedDescription, details: nil))
  }
}
