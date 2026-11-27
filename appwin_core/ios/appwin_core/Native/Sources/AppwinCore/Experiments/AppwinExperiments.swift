import Foundation

/// The A/B tests the dashboard runs on this app, read where the app decides
/// what to show (an onboarding, a paywall).
///
/// Values come from the server at `AppwinCore.configure(projectAppId:)` and are
/// frozen for the session: a screen never switches variant under the user's
/// eyes, and a change made in the dashboard applies at the next launch. The
/// very first launch waits about 1.5 s for the answer, then falls back to your
/// default. Offline, on an error or for an unknown key, every read answers
/// `nil`: keep your own default (the control) for that case.
///
/// The first read of a key in a session records an exposure, and every event
/// sent while the device is in a test carries `$feature/<key> = <variant>`, so
/// read the variant only where the user actually reaches the tested screen.
///
/// ```swift
/// switch await AppwinCore.experiments.variant("paywall_q4") {
/// case "test": showNewPaywall()
/// default: showCurrentPaywall()
/// }
/// ```
public struct AppwinExperiments: Sendable {
  init() {}

  /// The variant of `key` for this device: the variant key of a multivariate
  /// flag, `"true"` for a boolean flag that is on, `nil` otherwise (not in the
  /// test, unknown key, offline, `configure` not called).
  public func variant(_ key: String) async -> String? {
    await AppwinCore.experimentsStore?.variant(key)
  }

  /// The JSON payload of the variant this device is in, decoded as `T`.
  ///
  /// `nil` when the device is not in the test, when its variant has no
  /// payload, or when the payload does not decode as `T`.
  ///
  /// ```swift
  /// struct PaywallConfig: Decodable { let title: String; let trial: Bool }
  /// let config = await AppwinCore.experiments.config("paywall_q4", as: PaywallConfig.self)
  /// ```
  public func config<T: Decodable>(_ key: String, as type: T.Type = T.self) async -> T? {
    await AppwinCore.experimentsStore?.config(key, as: type)
  }
}

extension AppwinCore {
  /// The A/B tests of this app. See `AppwinExperiments`.
  public nonisolated static var experiments: AppwinExperiments { AppwinExperiments() }
}
