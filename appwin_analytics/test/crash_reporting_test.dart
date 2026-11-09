import 'dart:ui' show ErrorCallback, PlatformDispatcher;

import 'package:appwin_analytics/appwin_analytics.dart';
import 'package:appwin_analytics/appwin_analytics_platform_interface.dart';
import 'package:appwin_analytics/src/crash_handlers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class _Reported {
  _Reported(this.fatal, this.type, this.message, this.frames);
  final bool fatal;
  final String type;
  final String? message;
  final List<Map<String, Object>> frames;
}

class FakePlatform extends AppwinAnalyticsPlatform
    with MockPlatformInterfaceMixin {
  FakePlatform(this.verdict);

  final AppwinInitStatus verdict;
  bool? crashReportingArg;
  final reported = <_Reported>[];

  @override
  Future<AppwinInitResult> initialize({
    bool crashReporting = true,
    bool sessionReplay = true,
  }) async {
    crashReportingArg = crashReporting;
    return AppwinInitResult(verdict);
  }

  @override
  Future<void> recordBridgedError({
    required bool fatal,
    required String type,
    String? message,
    required List<Map<String, Object>> frames,
  }) async {
    reported.add(_Reported(fatal, type, message, frames));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FlutterExceptionHandler? savedFlutter;
  late ErrorCallback? savedDispatcher;

  setUp(() {
    savedFlutter = FlutterError.onError;
    savedDispatcher = PlatformDispatcher.instance.onError;
  });

  tearDown(() {
    uninstallCrashHandlers();
    FlutterError.onError = savedFlutter;
    PlatformDispatcher.instance.onError = savedDispatcher;
  });

  test('initialize forwards crashReporting to native', () async {
    final platform = FakePlatform(AppwinInitStatus.ready);
    AppwinAnalyticsPlatform.instance = platform;

    await AppwinAnalytics.instance.initialize(crashReporting: false);
    expect(platform.crashReportingArg, false);
  });

  test('framework errors reach native, then the previous handler', () async {
    final platform = FakePlatform(AppwinInitStatus.ready);
    AppwinAnalyticsPlatform.instance = platform;
    final previous = <FlutterErrorDetails>[];
    FlutterError.onError = previous.add;

    await AppwinAnalytics.instance.initialize(inAppPackages: ['my_shop']);
    final details = FlutterErrorDetails(
      exception: StateError('boom'),
      stack: StackTrace.fromString(
        '#0      Cart.add (package:my_shop/cart.dart:3:9)\n'
        '#1      Element.rebuild (package:flutter/src/widgets/framework.dart:1:1)',
      ),
    );
    FlutterError.onError!(details);

    expect(previous, [details]);
    expect(platform.reported, hasLength(1));
    final report = platform.reported.single;
    expect(report.fatal, false);
    expect(report.type, 'StateError');
    expect(report.message, 'Bad state: boom');
    expect(report.frames.map((f) => f['inApp']), [true, false]);
  });

  test('async errors reach native; the previous verdict wins', () async {
    final platform = FakePlatform(AppwinInitStatus.ready);
    AppwinAnalyticsPlatform.instance = platform;
    var previousCalls = 0;
    PlatformDispatcher.instance.onError = (error, stack) {
      previousCalls++;
      return false;
    };

    await AppwinAnalytics.instance.initialize();
    final handled = PlatformDispatcher.instance.onError!(
      ArgumentError('bad'),
      StackTrace.empty,
    );

    expect(handled, false);
    expect(previousCalls, 1);
    expect(platform.reported.single.type, 'ArgumentError');
  });

  test(
    'without a previous async handler the error counts as handled',
    () async {
      AppwinAnalyticsPlatform.instance = FakePlatform(AppwinInitStatus.ready);
      PlatformDispatcher.instance.onError = null;

      await AppwinAnalytics.instance.initialize();
      expect(
        PlatformDispatcher.instance.onError!(Exception('x'), StackTrace.empty),
        true,
      );
    },
  );

  test('a second initialize does not stack the hooks', () async {
    final platform = FakePlatform(AppwinInitStatus.ready);
    AppwinAnalyticsPlatform.instance = platform;
    FlutterError.onError = (_) {};

    await AppwinAnalytics.instance.initialize();
    await AppwinAnalytics.instance.initialize();
    FlutterError.onError!(FlutterErrorDetails(exception: Exception('x')));

    expect(platform.reported, hasLength(1));
  });

  test(
    'no hooks when crash reporting is off or Analytics unavailable',
    () async {
      FlutterError.onError = (_) {};
      final before = FlutterError.onError;

      AppwinAnalyticsPlatform.instance = FakePlatform(AppwinInitStatus.ready);
      await AppwinAnalytics.instance.initialize(crashReporting: false);
      expect(FlutterError.onError, same(before));

      AppwinAnalyticsPlatform.instance = FakePlatform(
        AppwinInitStatus.unavailable,
      );
      await AppwinAnalytics.instance.initialize();
      expect(FlutterError.onError, same(before));
    },
  );

  test('recordError sends type, message, frames and fatal', () async {
    final platform = FakePlatform(AppwinInitStatus.ready);
    AppwinAnalyticsPlatform.instance = platform;

    try {
      throw const FormatException('nope');
    } catch (e, s) {
      await AppwinAnalytics.instance.recordError(e, s, true);
    }

    final report = platform.reported.single;
    expect(report.fatal, true);
    expect(report.type, 'FormatException');
    expect(report.message, 'FormatException: nope');
    expect(report.frames.first['file'], endsWith('crash_reporting_test.dart'));
  });

  test('a failing sink never replaces the original error', () {
    final previous = <FlutterErrorDetails>[];
    FlutterError.onError = previous.add;
    installCrashHandlers((_, _) => throw StateError('reporter down'));

    FlutterError.onError!(FlutterErrorDetails(exception: Exception('x')));
    expect(previous, hasLength(1));
  });
}
