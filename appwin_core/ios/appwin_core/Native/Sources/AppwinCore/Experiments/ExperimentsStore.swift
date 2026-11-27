import Foundation
import os

/// One flag's value for this device, as `/api/sdk/v1/flags` evaluates it:
/// `false` (off or out of the rollout), `true` (a boolean flag that matches)
/// or the key of the variant a multivariate flag picked.
enum ExperimentFlagValue: Equatable, Sendable {
  case bool(Bool)
  case string(String)

  /// The variant the app reads: the variant key, `"true"` for a matching
  /// boolean flag, `nil` when the device is not in the flag.
  var variant: String? {
    switch self {
    case .string(let key): return key
    case .bool(true): return "true"
    case .bool(false): return nil
    }
  }

  /// The `$feature/<key>` value stamped on events, `nil` when not in the flag.
  var featureValue: AnalyticsValue? {
    switch self {
    case .string(let key): return .string(key)
    case .bool(true): return .bool(true)
    case .bool(false): return nil
    }
  }
}

/// The flags of one session: what the app reads until it is relaunched.
struct ExperimentsSnapshot: Equatable, Sendable {
  var flags: [String: ExperimentFlagValue] = [:]
  /// Each payload as its own JSON document, decoded on demand by `config`.
  var payloads: [String: Data] = [:]

  static let empty = ExperimentsSnapshot()

  /// Parses a `/api/sdk/v1/flags` body. `nil` when it has no `flags` object:
  /// such a body is never cached. `payloads` is optional (servers older than
  /// the A/B tests do not send it) and a malformed entry is skipped, never fatal.
  static func parse(_ body: Data) -> ExperimentsSnapshot? {
    guard let root = (try? JSONSerialization.jsonObject(with: body)) as? [String: Any],
          let rawFlags = root["flags"] as? [String: Any] else { return nil }
    var snapshot = ExperimentsSnapshot()
    for (key, raw) in rawFlags {
      // `NSNumber` bridges both JSON booleans and numbers: only a real boolean counts.
      if let number = raw as? NSNumber, CFGetTypeID(number) == CFBooleanGetTypeID() {
        snapshot.flags[key] = .bool(number.boolValue)
      } else if let string = raw as? String {
        snapshot.flags[key] = .string(string)
      }
    }
    if let rawPayloads = root["payloads"] as? [String: Any] {
      for (key, payload) in rawPayloads where !(payload is NSNull) {
        if let data = try? JSONSerialization.data(withJSONObject: payload, options: .fragmentsAllowed) {
          snapshot.payloads[key] = data
        }
      }
    }
    return snapshot
  }
}

/// What the last good `/api/sdk/v1/flags` answer left on disk.
struct ExperimentsCacheEntry: Codable, Equatable, Sendable {
  /// The `ETag` the server sent with it, replayed as `If-None-Match`.
  let etag: String?
  /// The body as received, parsed again at each launch.
  let body: Data
}

protocol ExperimentsCache: Sendable {
  func load() -> ExperimentsCacheEntry?
  func save(_ entry: ExperimentsCacheEntry)
}

/// The production cache: `UserDefaults`, keyed by app id so two apps sharing
/// a device (or a test host) never read each other's variants.
struct UserDefaultsExperimentsCache: ExperimentsCache {
  let key: String

  init(appId: String) { key = "appwin.core.experiments.\(appId)" }

  func load() -> ExperimentsCacheEntry? {
    guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
    return try? JSONDecoder().decode(ExperimentsCacheEntry.self, from: data)
  }

  func save(_ entry: ExperimentsCacheEntry) {
    if let data = try? JSONEncoder().encode(entry) {
      UserDefaults.standard.set(data, forKey: key)
    }
  }
}

/// The outcome of one conditional request to `/api/sdk/v1/flags`.
enum ExperimentsFetchOutcome: Sendable {
  case fresh(body: Data, etag: String?)
  case notModified
  case failed
}

/// The A/B tests of this launch (AB-2): fetched once at `configure`, cached on
/// disk with the server's ETag, and frozen for the session so a screen never
/// switches variant under the user's eyes.
///
/// - A launch with a cache freezes on it at once and refreshes it in the
///   background: the new answer applies at the next launch.
/// - The very first launch (no cache) lets a reader wait up to `firstLaunchWait`
///   for the answer, then freezes on nothing: the app shows its own default.
/// - Offline, an error, an unknown key: `nil`, never a crash.
final class ExperimentsStore: @unchecked Sendable {
  private struct State {
    var session: ExperimentsSnapshot?
    var exposed: Set<String> = []
    var refresh: Task<Void, Never>?
  }

  private let state = OSAllocatedUnfairLock(initialState: State())
  private let cache: any ExperimentsCache
  private let emit: @Sendable (String, [String: AnalyticsValue]) -> Void
  private let firstLaunchWait: Duration

  init(
    cache: any ExperimentsCache,
    firstLaunchWait: Duration = .milliseconds(1500),
    emit: @escaping @Sendable (String, [String: AnalyticsValue]) -> Void
  ) {
    self.cache = cache
    self.firstLaunchWait = firstLaunchWait
    self.emit = emit
    if let cached = cache.load(), let snapshot = ExperimentsSnapshot.parse(cached.body) {
      state.withLock { $0.session = snapshot }
    }
  }

  /// Starts the background refresh. `fetch` gets the cached ETag (`nil` without
  /// a cache). Called once, by `configure`.
  func start(fetch: @escaping @Sendable (_ etag: String?) async -> ExperimentsFetchOutcome) {
    let etag = cache.load()?.etag
    let task = Task { [weak self] in
      let outcome = await fetch(etag)
      self?.apply(outcome)
    }
    state.withLock { $0.refresh = task }
  }

  private func apply(_ outcome: ExperimentsFetchOutcome) {
    switch outcome {
    case .fresh(let body, let etag):
      guard let snapshot = ExperimentsSnapshot.parse(body) else {
        freeze(.empty)
        return
      }
      cache.save(ExperimentsCacheEntry(etag: etag, body: body))
      freeze(snapshot)
    case .notModified:
      // Only sent with a cache, which the session already froze on.
      break
    case .failed:
      freeze(.empty)
    }
  }

  /// Sets the session's snapshot unless one is set already, and returns the one
  /// in force: the first answer wins, later ones wait for the next launch.
  @discardableResult
  private func freeze(_ candidate: ExperimentsSnapshot) -> ExperimentsSnapshot {
    state.withLock { state in
      if let session = state.session { return session }
      state.session = candidate
      return candidate
    }
  }

  /// The session's snapshot, waiting for the first answer when there is none yet.
  func session() async -> ExperimentsSnapshot {
    let (session, refresh) = state.withLock { ($0.session, $0.refresh) }
    if let session { return session }
    let wait = firstLaunchWait
    // A race the slower side cannot hold up: a task group would wait for both
    // children, and awaiting a `Task`'s value does not end on cancellation.
    await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
      let resumed = OSAllocatedUnfairLock(initialState: false)
      let resumeOnce: @Sendable () -> Void = {
        if resumed.withLock({ done in defer { done = true }; return !done }) { continuation.resume() }
      }
      Task { await refresh?.value; resumeOnce() }
      Task { try? await Task.sleep(for: wait); resumeOnce() }
    }
    return freeze(.empty)
  }

  func variant(_ key: String) async -> String? {
    let variant = await session().flags[key]?.variant
    if let variant { exposeOnce(key, variant: variant) }
    return variant
  }

  /// The payload of `key`, `nil` when the device is not in the flag, when the
  /// flag has no payload, or when it does not decode as `T`.
  func config<T: Decodable>(_ key: String, as type: T.Type) async -> T? {
    let session = await session()
    guard let variant = session.flags[key]?.variant else { return nil }
    exposeOnce(key, variant: variant)
    guard let data = session.payloads[key] else { return nil }
    return try? JSONDecoder().decode(T.self, from: data)
  }

  /// `experiment_exposure` at the first read of a key in this session: the
  /// denominator of the test. The name is frozen once published.
  private func exposeOnce(_ key: String, variant: String) {
    let first = state.withLock { $0.exposed.insert(key).inserted }
    if first { emit("experiment_exposure", ["key": .string(key), "variant": .string(variant)]) }
  }

  /// `$feature/<key> = <variant>` for each flag this device is in, stamped on
  /// every event. Empty until the session is frozen.
  func featureProps() -> [String: AnalyticsValue] {
    guard let session = state.withLock({ $0.session }) else { return [:] }
    var props: [String: AnalyticsValue] = [:]
    for (key, value) in session.flags {
      if let feature = value.featureValue { props["$feature/\(key)"] = feature }
    }
    return props
  }
}

private let experimentsStoreHolder = OSAllocatedUnfairLock<ExperimentsStore?>(initialState: nil)

extension AppwinCore {
  nonisolated static var experimentsStore: ExperimentsStore? {
    experimentsStoreHolder.withLock { $0 }
  }

  /// Built by `configure`, once per app id: a second `configure` with the same
  /// id keeps the session's frozen values.
  static func startExperiments(appId: String, client: ClientApi) {
    let cache = UserDefaultsExperimentsCache(appId: appId)
    if experimentsStoreHolder.withLock({ $0?.cacheKey }) == cache.key { return }
    let store = ExperimentsStore(cache: cache) { name, props in
      // Straight into the pipeline, not on the bus: an exposure is AppWin's
      // measure, never an event for the ad networks' adapters.
      guard let pipeline = AppwinCore.analyticsPipeline else { return }
      let occurredAt = Date()
      Task { await pipeline.enqueueAutomatic(name: name, props: props, occurredAt: occurredAt) }
    }
    experimentsStoreHolder.withLock { $0 = store }
    store.start { etag in await fetchFlags(client: client, etag: etag) }
  }

  /// Test-only: forgets the store so the next `configure` builds a new one.
  nonisolated static func resetExperimentsForTesting() {
    experimentsStoreHolder.withLock { $0 = nil }
  }

  /// `GET /api/sdk/v1/flags`, conditional on the cached ETag. Bearer-only: it
  /// waits for the session first, and mints it again once after a 401.
  nonisolated static func fetchFlags(client: ClientApi, etag: String?) async -> ExperimentsFetchOutcome {
    _ = try? await bootstrapSession()
    var headers: [String: String] = [:]
    if let etag { headers["If-None-Match"] = etag }
    for attempt in 0..<2 {
      do {
        let response = try await client.requestConditional(
          path: "/api/sdk/v1/flags", extraHeaders: headers)
        if response.status == 304 { return .notModified }
        return .fresh(body: response.data, etag: response.etag)
      } catch AppwinApiError.http(let status) where status == 401 && attempt == 0 {
        _ = try? await bootstrapSession()
      } catch {
        return .failed
      }
    }
    return .failed
  }
}

extension ExperimentsStore {
  /// Which cache this store reads, to tell a repeated `configure` from another app.
  var cacheKey: String? { (cache as? UserDefaultsExperimentsCache)?.key }
}
