/// Feeds the native recorder the masks of what Flutter draws.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

import 'replay_masks.dart';

/// Reads the rules of the running recording, `null` when nothing records.
typedef ReplayRulesReader = Future<ReplayMaskRules?> Function();

/// Sends masks as flat `[left, top, right, bottom, ...]` logical pixels.
typedef ReplayMasksWriter = Future<void> Function(List<double> rects);

/// Collects the masks after the frames that changed the screen, at most every
/// [minInterval], and sends them when they changed. The rules are polled
/// every [pollInterval], since the native recorder starts, stops and changes
/// them on its own; each poll also resends the set, because the native side
/// masks the whole surface once the last one is 2.5 s old.
class ReplayMaskReporter {
  /// A reporter over the given native calls.
  ReplayMaskReporter({
    required this.readRules,
    required this.writeMasks,
    this.minInterval = const Duration(milliseconds: 250),
    this.pollInterval = const Duration(seconds: 1),
  });

  /// Native rules reader.
  final ReplayRulesReader readRules;

  /// Native masks writer.
  final ReplayMasksWriter writeMasks;

  /// Shortest gap between two collections. The capture runs at one frame per
  /// second: a quarter of that keeps a fresh set close to each capture.
  final Duration minInterval;

  /// Gap between two reads of the native rules, and between two sends.
  final Duration pollInterval;

  bool _started = false;
  Timer? _poll;
  Timer? _pending;
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
    _refreshRules();
  }

  /// Stops the timers; for tests.
  @visibleForTesting
  void stop() {
    _rules = null;
    _poll?.cancel();
    _pending?.cancel();
    _poll = null;
    _pending = null;
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
    List<Rect> rects;
    try {
      rects = collectReplayMasks(view, rules);
    } catch (_) {
      // A tree this walk cannot read is hidden whole rather than shown.
      rects = [Offset.zero & view.size];
    }
    final flat = <double>[
      for (final rect in rects) ...[rect.left, rect.top, rect.right, rect.bottom],
    ];
    if (listEquals(flat, _lastSent)) return;
    _lastSent = flat;
    writeMasks(flat).catchError((Object _) {
      _lastSent = null;
    });
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
