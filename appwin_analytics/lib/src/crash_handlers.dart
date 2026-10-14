/// Global Dart error hooks for crash reporting (ADR-0056).
library;

import 'dart:ui' show ErrorCallback, PlatformDispatcher;

import 'package:flutter/foundation.dart';

/// Receives every uncaught Dart error once the hooks are installed.
typedef DartErrorSink = void Function(Object error, StackTrace? stack);

bool _installed = false;
FlutterExceptionHandler? _previousFlutter;
ErrorCallback? _previousDispatcher;

/// Hooks `FlutterError.onError` (framework errors: build, layout, paint,
/// gestures) and `PlatformDispatcher.onError` (everything else that escapes
/// a zone: futures, timers, isolate messages). Idempotent.
///
/// Both previous handlers keep running after [sink], so Crashlytics, Sentry
/// or the default console dump still see every error.
void installCrashHandlers(DartErrorSink sink) {
  if (_installed) return;
  _installed = true;

  final previousFlutter = _previousFlutter = FlutterError.onError;
  FlutterError.onError = (details) {
    _safely(() => sink(details.exception, details.stack));
    previousFlutter?.call(details);
  };

  final previousDispatcher = _previousDispatcher =
      PlatformDispatcher.instance.onError;
  PlatformDispatcher.instance.onError = (error, stack) {
    _safely(() => sink(error, stack));
    // A previous handler's answer wins; alone, the error counts as handled
    // (`true`) since it has been reported.
    return previousDispatcher?.call(error, stack) ?? true;
  };
}

/// Restores the handlers found at install time.
@visibleForTesting
void uninstallCrashHandlers() {
  if (!_installed) return;
  FlutterError.onError = _previousFlutter;
  PlatformDispatcher.instance.onError = _previousDispatcher;
  _previousFlutter = null;
  _previousDispatcher = null;
  _installed = false;
}

// The reporter runs inside the app's own error path: a failure there must
// neither replace the original error nor recurse into these hooks.
void _safely(void Function() body) {
  try {
    body();
  } catch (e) {
    if (kDebugMode) debugPrint('[Appwin] crash capture failed: $e');
  }
}
