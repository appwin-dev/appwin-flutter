/// Feeds the native recorder the masks of what Flutter draws.
library;

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

import 'replay_masks.dart';

/// Reads the rules of the running recording, `null` when nothing records.
typedef ReplayRulesReader = Future<ReplayMaskRules?> Function();

/// Sends masks as flat `[left, top, right, bottom, ...]` logical pixels.
typedef ReplayMasksWriter = Future<void> Function(List<double> rects);

/// Sends a rendered frame, RGBA, with the masks of that same frame.
typedef ReplayFrameWriter = Future<void> Function(
  Uint8List rgba,
  int width,
  int height,
  List<double> rects,
);

/// Pixels per logical pixel, `REPLAY_LIMITS.captureScale` of the contracts.
const double _captureScale = 2;

/// Collects the masks after the frames that changed the screen, at most every
/// [minInterval], and sends them when they changed. The rules are polled
/// every [pollInterval], since the native recorder starts, stops and changes
/// them on its own; each poll also resends the set, because the native side
/// masks the whole surface once the last one is 2.5 s old.
///
/// When the rules ask for it ([ReplayMaskRules.captureFrames]), it also
/// renders a frame every [frameInterval] and sends it with its masks. The
/// engine renders it on its own threads: the UI thread only spends the mask
/// walk (0.1 ms measured on an iPhone 15, against about 150 ms of main thread
/// for a native capture of the same screen).
class ReplayMaskReporter {
  /// A reporter over the given native calls.
  ReplayMaskReporter({
    required this.readRules,
    required this.writeMasks,
    this.writeFrame,
    this.frameInterval = const Duration(seconds: 1),
    this.minInterval = const Duration(milliseconds: 250),
    this.pollInterval = const Duration(seconds: 1),
  });

  /// Native rules reader.
  final ReplayRulesReader readRules;

  /// Native masks writer.
  final ReplayMasksWriter writeMasks;

  /// Native frame writer, `null` where the native side captures itself.
  final ReplayFrameWriter? writeFrame;

  /// Gap between two rendered frames: the recording's frame rate.
  final Duration frameInterval;

  /// Shortest gap between two collections. The capture runs at one frame per
  /// second: a quarter of that keeps a fresh set close to each capture.
  final Duration minInterval;

  /// Gap between two reads of the native rules, and between two sends.
  final Duration pollInterval;

  bool _started = false;
  Timer? _poll;
  Timer? _pending;
  Timer? _frames;
  bool _rendering = false;
  ReplayMaskRules? _rules;
  List<double>? _lastSent;
  final Stopwatch _sinceCollect = Stopwatch();

  /// Starts reporting. Idempotent.
  void start() {
    if (_started) return;
    // A persistent callback cannot be removed: it stays, and returns early
    // while nothing records.
    SchedulerBinding.instance.addPersistentFrameCallback((_) => _schedule());
    _started = true;
    _poll = Timer.periodic(pollInterval, (_) => _refreshRules());
    if (writeFrame != null) _frames = Timer.periodic(frameInterval, (_) => _renderFrame());
    _refreshRules();
  }

  /// Stops the timers; for tests.
  @visibleForTesting
  void stop() {
    _rules = null;
    _poll?.cancel();
    _pending?.cancel();
    _frames?.cancel();
    _poll = null;
    _pending = null;
    _frames = null;
  }

  Future<void> _refreshRules() async {
    ReplayMaskRules? rules;
    try {
      rules = await readRules();
    } catch (_) {
      rules = null;
    }
    _rules = rules;
    _lastSent = null;
    _schedule();
  }

  void _schedule() {
    if (_rules == null || _pending != null) return;
    final elapsed = _sinceCollect.isRunning ? _sinceCollect.elapsed : minInterval;
    final wait = elapsed >= minInterval ? Duration.zero : minInterval - elapsed;
    _pending = Timer(wait, _collectAndSend);
  }

  void _collectAndSend() {
    _pending = null;
    final rules = _rules;
    final view = _implicitRenderView();
    if (rules == null || view == null) return;
    _sinceCollect
      ..reset()
      ..start();
    final flat = _masks(view, rules);
    if (listEquals(flat, _lastSent)) return;
    _lastSent = flat;
    writeMasks(flat).catchError((Object _) {
      _lastSent = null;
    });
  }

  List<double> _masks(RenderView view, ReplayMaskRules rules) {
    List<Rect> rects;
    try {
      rects = collectReplayMasks(view, rules);
    } catch (_) {
      // A tree this walk cannot read is hidden whole rather than shown.
      rects = [Offset.zero & view.size];
    }
    return [for (final rect in rects) ...[rect.left, rect.top, rect.right, rect.bottom]];
  }

  Future<void> _renderFrame() async {
    final writer = writeFrame;
    final rules = _rules;
    final view = _implicitRenderView();
    final lifecycle = SchedulerBinding.instance.lifecycleState;
    // Backgrounded, iOS refuses the GPU work; and one frame at a time.
    if (writer == null || rules == null || !rules.captureFrames || view == null || _rendering ||
        (lifecycle != null && lifecycle != AppLifecycleState.resumed)) {
      return;
    }
    // ignore: invalid_use_of_protected_member
    final layer = view.layer;
    if (layer is! OffsetLayer) return;
    _rendering = true;
    try {
      // Read now, from the tree the layers were painted from: the masks
      // match the frame even mid-scroll.
      final rects = _masks(view, rules);
      final ratio = view.flutterView.devicePixelRatio;
      // The root layer scales logical pixels to physical ones: its bounds are
      // physical, and the ratio undoes that scale down to the capture's.
      final image = await layer.toImage(
        Offset.zero & (view.size * ratio),
        pixelRatio: math.min(_captureScale, ratio) / ratio,
      );
      try {
        final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        if (bytes == null || _rules == null) return;
        await writer(
          bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
          image.width,
          image.height,
          rects,
        );
      } finally {
        image.dispose();
      }
    } catch (_) {
      // Nothing sent: the native side captures again once the last frame is stale.
    } finally {
      _rendering = false;
    }
  }

  /// The view the native recorder captures: mobile embedders have one.
  RenderView? _implicitRenderView() {
    final implicit = PlatformDispatcher.instance.implicitView;
    RenderView? first;
    for (final view in RendererBinding.instance.renderViews) {
      if (view.flutterView == implicit) return view;
      first ??= view;
    }
    return first;
  }
}
