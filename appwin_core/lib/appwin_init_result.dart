/// The verdict a product's `initialize()` returns.
///
/// Exported by `package:appwin_core/appwin_core.dart`, and shared by Support,
/// Community and Notifications so a host app has one shape to handle whichever
/// products it embeds.
library;

/// Why a product is closed to this app.
enum AppwinUnavailableReason {
  /// The organisation's plan does not include this product. The studio cannot
  /// fix this from the dashboard: it is a sales conversation.
  plan,

  /// The product is switched off for this project. The studio turns it back on
  /// from the dashboard, without shipping an app update.
  disabled,
}

/// Coarse outcome of a product's `initialize()`.
enum AppwinInitStatus {
  /// Ready to present. The only value that unlocks the product's UI.
  ready,

  /// The server answered, and the answer is no. See
  /// [AppwinInitResult.reason].
  unavailable,

  /// `AppwinCore.instance.configure()` was never called.
  notConfigured,

  /// No verdict could be obtained and nothing was cached from a previous
  /// launch. No network is one cause; an API too old to serve the endpoint is
  /// another. Retry later; this is not a permanent no.
  unknown,
}

/// What a product's `initialize()` answers.
///
/// A value rather than a thrown exception, deliberately. "Not entitled" is an
/// expected outcome of a normal launch, not an error: forcing callers into a
/// try/catch for the ordinary case pushes them towards swallowing it.
///
/// ```dart
/// final support = await AppwinSupport.instance.initialize();
/// if (support.isReady) {
///   setState(() => _showHelpButton = true);
/// }
/// ```
class AppwinInitResult {
  /// Builds a result. Products return one from `initialize()`; you rarely
  /// construct it yourself, outside a test double.
  const AppwinInitResult(this.status, {this.reason});

  /// The outcome. Prefer [isReady] over comparing this by hand.
  final AppwinInitStatus status;

  /// Set only when [status] is [AppwinInitStatus.unavailable].
  final AppwinUnavailableReason? reason;

  /// The one check a host app needs before showing a product's entry point.
  bool get isReady => status == AppwinInitStatus.ready;

  /// Parses what the native side sends over the method channel.
  ///
  /// An unknown string maps to [AppwinInitStatus.unknown] rather than throwing:
  /// a Dart package is often older than the native SDK it talks to, and a value
  /// it has never heard of must not crash the host app.
  factory AppwinInitResult.fromMap(Map<Object?, Object?>? map) {
    final status = switch (map?['status']) {
      'ready' => AppwinInitStatus.ready,
      'unavailable' => AppwinInitStatus.unavailable,
      'notConfigured' => AppwinInitStatus.notConfigured,
      _ => AppwinInitStatus.unknown,
    };
    final reason = switch (map?['reason']) {
      'plan' => AppwinUnavailableReason.plan,
      'disabled' => AppwinUnavailableReason.disabled,
      _ => null,
    };
    return AppwinInitResult(status, reason: reason);
  }

  @override
  String toString() =>
      'AppwinInitResult(${status.name}${reason == null ? '' : ', ${reason!.name}'})';
}
