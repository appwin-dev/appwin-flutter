import 'package:appwin_core_example/main.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// The example stands in for a host app, so what these tests pin down is the
/// part a studio copies: read the device id on start, then swap the identity
/// on sign in and sign out.
///
/// The native side is stubbed. A widget test has no plugin behind the channel,
/// and the point here is the Dart wiring, not the SDK itself.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('appwin_core');
  final calls = <String>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call.method);
          return switch (call.method) {
            'deviceId' => 'device-abc',
            'bootstrapSession' => 'token',
            _ => null,
          };
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  testWidgets('shows the device id once configure has run', (tester) async {
    await tester.pumpWidget(const ExampleApp());
    await tester.pumpAndSettle();

    expect(find.text('Device: device-abc'), findsOneWidget);
    expect(find.text('Anonymous'), findsOneWidget);
  });

  testWidgets('identifies, then opens the session so it carries the identity', (
    tester,
  ) async {
    await tester.pumpWidget(const ExampleApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Identify user'));
    await tester.pumpAndSettle();

    expect(calls, containsAllInOrder(['identify', 'bootstrapSession']));
    expect(find.text('Identified as user-42'), findsOneWidget);
  });

  testWidgets('goes back to anonymous on sign out', (tester) async {
    await tester.pumpWidget(const ExampleApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Identify user'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();

    expect(calls, contains('signOut'));
    expect(find.text('Anonymous'), findsOneWidget);
  });
}
