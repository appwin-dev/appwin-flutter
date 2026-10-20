import 'dart:typed_data';

import 'package:appwin_analytics/src/replay_masks.dart';
import 'package:appwin_analytics/src/replay_reporter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _all = ReplayMaskRules(maskAllText: true, maskAllImages: true);
const _none = ReplayMaskRules(maskAllText: false, maskAllImages: false);

Widget _app(Widget body) => MaterialApp(home: Scaffold(body: body));

List<Rect> _masks(WidgetTester tester, ReplayMaskRules rules) =>
    collectReplayMasks(tester.binding.renderViews.first, rules);

Rect _rectOf(WidgetTester tester, Finder finder) => tester.getRect(finder);

void main() {
  testWidgets('text fields are masked whatever the rules', (tester) async {
    await tester.pumpWidget(_app(const Column(children: [
      Text('hello'),
      TextField(),
      AppwinUnmask(child: TextField(key: Key('unmasked'))),
    ])));

    final masks = _masks(tester, _none);
    expect(masks, hasLength(2));
    expect(masks, contains(_rectOf(tester, find.byType(EditableText).first)));
    expect(
      masks,
      contains(_rectOf(
        tester,
        find.descendant(of: find.byKey(const Key('unmasked')), matching: find.byType(EditableText)),
      )),
    );
  });

  testWidgets('texts and images follow the rules', (tester) async {
    await tester.pumpWidget(_app(const Column(children: [
      Text('hello'),
      RawImage(width: 40, height: 40),
    ])));

    expect(_masks(tester, _all), hasLength(2));
    expect(_masks(tester, _none), isEmpty);
    expect(
      _masks(tester, const ReplayMaskRules(maskAllText: false, maskAllImages: true)),
      [_rectOf(tester, find.byType(RawImage))],
    );
  });

  testWidgets('AppwinUnmask spares texts, AppwinMask hides its subtree', (tester) async {
    await tester.pumpWidget(_app(const Column(children: [
      AppwinUnmask(child: Text('public')),
      AppwinMask(child: SizedBox(width: 100, height: 30, child: Text('secret'))),
    ])));

    final secret = _rectOf(tester, find.byType(AppwinMask));
    expect(_masks(tester, _all), [secret]);
    expect(_masks(tester, _none), [secret]);
  });

  testWidgets('what is not painted is not masked', (tester) async {
    await tester.pumpWidget(_app(ListView(children: [
      const Offstage(child: Text('offstage')),
      const Opacity(opacity: 0, child: Text('transparent')),
      const Text('visible'),
      for (var i = 0; i < 100; i++) const SizedBox(height: 50, child: Text('row')),
    ])));

    final masks = _masks(tester, _all);
    expect(masks, contains(_rectOf(tester, find.text('visible'))));
    final view = tester.view.physicalSize / tester.view.devicePixelRatio;
    for (final rect in masks) {
      expect(rect.bottom, lessThanOrEqualTo(view.height));
    }
    // 1 visible text plus the rows the viewport shows, not the hundred.
    expect(masks.length, lessThan(20));
  });

  testWidgets('a route below an opaque one is not masked', (tester) async {
    await tester.pumpWidget(_app(const Text('first')));
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.push(MaterialPageRoute<void>(builder: (_) => const Scaffold(body: SizedBox())));
    await tester.pumpAndSettle();

    expect(_masks(tester, _all), isEmpty);
  });

  testWidgets('the reporter sends on change, and resends on each poll', (tester) async {
    final sent = <List<double>>[];
    final reporter = ReplayMaskReporter(
      readRules: () async => _none,
      writeMasks: (rects) async => sent.add(rects),
      minInterval: Duration.zero,
    );
    await tester.pumpWidget(_app(const TextField()));
    reporter.start();
    await tester.pump(const Duration(milliseconds: 10));
    await tester.pump(const Duration(milliseconds: 10));

    expect(sent, hasLength(1));
    final field = _rectOf(tester, find.byType(EditableText));
    expect(sent.single, [field.left, field.top, field.right, field.bottom]);

    await tester.pump(const Duration(milliseconds: 10));
    expect(sent, hasLength(1));

    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 10));
    expect(sent, hasLength(2));
    reporter.stop();
  });

  testWidgets('frames are rendered at two pixels per point, with the masks of the same frame', (tester) async {
    tester.view.physicalSize = const Size(300, 600);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final frames = <({Uint8List rgba, int width, int height, List<double> rects})>[];
    final reporter = ReplayMaskReporter(
      readRules: () async => const ReplayMaskRules(
        maskAllText: false,
        maskAllImages: false,
        captureFrames: true,
      ),
      writeMasks: (_) async {},
      writeFrame: (rgba, width, height, rects) async =>
          frames.add((rgba: rgba, width: width, height: height, rects: rects)),
      frameInterval: const Duration(milliseconds: 50),
    );
    await tester.pumpWidget(_app(const Column(children: [Spacer(), TextField()])));
    reporter.start();
    // The timers run on the test's fake clock, the engine's rendering on the real one.
    for (var i = 0; i < 40 && frames.isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 60));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    }
    reporter.stop();

    final frame = frames.first;
    // 100 x 200 logical pixels, the device's 3x brought down to 2x.
    expect((frame.width, frame.height), (200, 400));
    expect(frame.rgba.lengthInBytes, 200 * 400 * 4);
    // The text field, in logical pixels, read from the same frame.
    final field = _rectOf(tester, find.byType(EditableText));
    expect(frame.rects, [field.left, field.top, field.right, field.bottom]);
  });
}
