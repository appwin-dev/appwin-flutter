/// Dart stack traces to the crash frame shape of ADR-0056
/// (`CrashFrameSchema` in `@app-win/contracts`).
library;

/// Contract bounds, mirrored here so an oversized trace is cut before it
/// crosses the method channel rather than after.
const int maxFrames = 200;
const int maxMessage = 1024;
const int _maxFn = 512;
const int _maxModule = 256;

// `#12     Foo.bar.<anonymous closure> (package:my_app/foo.dart:12:5)`.
// The member is greedy so a `(` inside it never splits the location; the URI
// is lazy so the trailing `:line:col` is not swallowed by `package:` itself.
final RegExp _vmFrame = RegExp(
  r'^#\d+\s+(.+)\s+\((\S+?)(?::(\d+))?(?::(\d+))?\)$',
);

// `#00 abs 0000007a1b4d5e6f virt 00000000002a5e6f _kDartIsolateSnapshotInstructions+0x1a5e6f`,
// emitted by `--obfuscate` / `--split-debug-info` builds.
final RegExp _dwarfFrame = RegExp(r'^#\d+\s+abs\s+[0-9a-f]+\b');
final RegExp _buildId = RegExp(r"^build_id:\s*'?([0-9a-fA-F]+)'?");

/// Parses [stack] into bridge frames (`fn`, `file`, `line`, `col`, `module`,
/// `inApp`), innermost first. Null keys are omitted rather than sent as
/// `null`, which reaches Swift as `NSNull`.
///
/// [inAppPackages] names the studio's own Dart packages. Empty means "every
/// `package:` URI except Flutter's and Appwin's".
List<Map<String, Object>> parseDartStack(
  StackTrace? stack, {
  List<String> inAppPackages = const [],
}) {
  if (stack == null) return const [];
  final lines = stack.toString().split('\n').map((l) => l.trim());
  final frames = <Map<String, Object>>[];
  String? buildId;
  for (final line in lines) {
    if (frames.length >= maxFrames) break;
    if (line.isEmpty || line == '<asynchronous suspension>') continue;

    final id = _buildId.firstMatch(line);
    if (id != null) {
      buildId = id.group(1);
      continue;
    }
    // Checked before the VM form, which it would otherwise half-match.
    if (_dwarfFrame.hasMatch(line)) {
      // Unreadable until the debug symbols are uploaded (ADR-0056 phase 3):
      // the raw line keeps both addresses for the symbolication worker, the
      // build id ties it to the right symbol file. Never in-app: an address
      // alone cannot tell app code from Flutter's.
      frames.add({
        'fn': _cap(line, _maxFn),
        'module': ?buildId,
        'inApp': false,
      });
      continue;
    }
    final match = _vmFrame.firstMatch(line);
    if (match == null) continue;
    final uri = match.group(2)!;
    final lineNo = int.tryParse(match.group(3) ?? '');
    final col = int.tryParse(match.group(4) ?? '');
    final module = _moduleOf(uri);
    frames.add({
      'fn': _cap(match.group(1)!, _maxFn),
      'file': _cap(uri, _maxFn),
      'line': ?lineNo,
      'col': ?col,
      if (module != null) 'module': _cap(module, _maxModule),
      'inApp': isInApp(uri, inAppPackages),
    });
  }
  // An unknown format still beats an empty stack in the dashboard.
  if (frames.isEmpty) {
    for (final line in lines) {
      if (frames.length >= maxFrames) break;
      if (line.isEmpty || line == '<asynchronous suspension>') continue;
      frames.add({'fn': _cap(line, _maxFn), 'inApp': false});
    }
  }
  return frames;
}

/// Whether a frame at [uri] is the studio's code. Only these frames feed
/// the issue fingerprint, so a false positive on Flutter's own frames would
/// merge unrelated issues.
bool isInApp(String uri, List<String> inAppPackages) {
  if (!uri.startsWith('package:')) return false;
  if (inAppPackages.isNotEmpty) {
    return inAppPackages.any((p) => uri.startsWith('package:$p/'));
  }
  return !uri.startsWith('package:flutter/') &&
      !uri.startsWith('package:appwin_');
}

/// `package:my_app/foo.dart` -> `my_app`, `dart:async/zone.dart` ->
/// `dart:async`. File URIs carry no library name.
String? _moduleOf(String uri) {
  if (uri.startsWith('package:')) {
    final slash = uri.indexOf('/');
    return slash > 8 ? uri.substring(8, slash) : null;
  }
  if (uri.startsWith('dart:')) {
    final slash = uri.indexOf('/');
    return slash > 0 ? uri.substring(0, slash) : uri;
  }
  return null;
}

String _cap(String value, int max) =>
    value.length <= max ? value : value.substring(0, max);

/// `error.toString()` bounded to the contract, never throwing: a faulty
/// `toString` override must not cost the report.
String? describeError(Object error) {
  String text;
  try {
    text = error.toString();
  } catch (_) {
    return null;
  }
  return _cap(text, maxMessage);
}
