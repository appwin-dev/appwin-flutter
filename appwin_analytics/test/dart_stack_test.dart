import 'package:appwin_analytics/src/dart_stack.dart';
import 'package:flutter_test/flutter_test.dart';

const _vmTrace = '''
#0      CheckoutPage._pay (package:my_shop/checkout.dart:42:7)
#1      _CheckoutPageState.build.<anonymous closure> (package:my_shop/checkout.dart:88:21)
#2      _InkResponseState.handleTap (package:flutter/src/material/ink_well.dart:1170:21)
<asynchronous suspension>
#3      _rootRun (dart:async/zone.dart:1399:13)
#4      main (file:///Users/dev/my_shop/lib/main.dart:10)
#5      AppwinAnalytics.recordError (package:appwin_analytics/appwin_analytics.dart:5:1)
#6      Client.get (package:http/src/client.dart:20:3)
''';

const _obfuscatedTrace = '''
*** *** *** *** *** *** *** *** *** *** *** *** *** *** *** ***
pid: 12345, tid: 12367, name 1.ui
os: android arch: arm64 comp: yes sim: no
build_id: 'f1c3b2a4e5d6c7b8a9f0e1d2c3b4a5f6'
isolate_dso_base: 7a1b2c3000, vm_dso_base: 7a1b2c3000
isolate_instructions: 7a1b3c0000, vm_instructions: 7a1b3b0000
    #00 abs 0000007a1b4d5e6f virt 00000000002a5e6f _kDartIsolateSnapshotInstructions+0x1a5e6f
    #01 abs 0000007a1b4d1234 virt 00000000002a1234 _kDartIsolateSnapshotInstructions+0x1a1234
<asynchronous suspension>
''';

void main() {
  group('parseDartStack, VM format', () {
    final frames = parseDartStack(StackTrace.fromString(_vmTrace));

    test('skips async suspension markers', () {
      expect(frames, hasLength(7));
    });

    test('splits member, file, line and column', () {
      expect(frames[0], {
        'fn': 'CheckoutPage._pay',
        'file': 'package:my_shop/checkout.dart',
        'line': 42,
        'col': 7,
        'module': 'my_shop',
        'inApp': true,
      });
      expect(frames[1]['fn'], '_CheckoutPageState.build.<anonymous closure>');
    });

    test('omits what the frame does not carry', () {
      expect(frames[4], {
        'fn': 'main',
        'file': 'file:///Users/dev/my_shop/lib/main.dart',
        'line': 10,
        'inApp': false,
      });
    });

    test('names dart: libraries as their module', () {
      expect(frames[3]['module'], 'dart:async');
      expect(frames[3]['inApp'], false);
    });

    test('default in-app: any package but Flutter and Appwin', () {
      expect(frames.map((f) => f['inApp']), [
        true, // my_shop
        true, // my_shop
        false, // flutter
        false, // dart:async
        false, // file://
        false, // appwin_analytics
        true, // http
      ]);
    });

    test('explicit in-app packages win over the default', () {
      final scoped = parseDartStack(
        StackTrace.fromString(_vmTrace),
        inAppPackages: ['my_shop'],
      );
      expect(scoped.where((f) => f['inApp'] == true), hasLength(2));
      expect(scoped[6]['inApp'], false);
    });
  });

  group('parseDartStack, obfuscated format', () {
    final frames = parseDartStack(StackTrace.fromString(_obfuscatedTrace));

    test('keeps each raw line, tagged with the build id', () {
      expect(frames, hasLength(2));
      expect(frames[0], {
        'fn':
            '#00 abs 0000007a1b4d5e6f virt 00000000002a5e6f _kDartIsolateSnapshotInstructions+0x1a5e6f',
        'module': 'f1c3b2a4e5d6c7b8a9f0e1d2c3b4a5f6',
        'inApp': false,
      });
    });
  });

  test('null and empty stacks give no frames', () {
    expect(parseDartStack(null), isEmpty);
    expect(parseDartStack(StackTrace.empty), isEmpty);
  });

  test('an unknown format falls back to raw lines', () {
    final frames = parseDartStack(
      StackTrace.fromString('package:my_shop/a.dart 12:5  Foo.bar\n'),
    );
    expect(frames, [
      {'fn': 'package:my_shop/a.dart 12:5  Foo.bar', 'inApp': false},
    ]);
  });

  test('caps the frame count', () {
    final huge = List.generate(
      300,
      (i) => '#$i      f$i (package:my_shop/a.dart:$i:1)',
    ).join('\n');
    expect(parseDartStack(StackTrace.fromString(huge)), hasLength(maxFrames));
  });

  test('a live trace parses', () {
    final frames = parseDartStack(StackTrace.current);
    expect(frames, isNotEmpty);
    expect(frames.first['file'], endsWith('dart_stack_test.dart'));
  });

  group('describeError', () {
    test('truncates to the contract bound', () {
      expect(describeError('x' * 5000), hasLength(maxMessage));
    });

    test('survives a throwing toString', () {
      expect(describeError(_Hostile()), isNull);
    });
  });
}

class _Hostile {
  @override
  String toString() => throw StateError('no');
}
