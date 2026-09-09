import 'package:flutter_test/flutter_test.dart';

import 'package:appwin_support_example/main.dart';

/// The example shows what a host app is supposed to do: decide what to render
/// from what `initialize()` answered. That decision is what these two tests
/// pin down, since it is the part a studio copies.
void main() {
  testWidgets('offers support when it is available', (tester) async {
    await tester.pumpWidget(const ExampleApp(supportReady: true));

    expect(find.text('Open support'), findsOneWidget);
  });

  testWidgets('offers nothing when it is not', (tester) async {
    await tester.pumpWidget(const ExampleApp(supportReady: false));

    expect(find.text('Open support'), findsNothing);
    expect(find.text('Support is not available for this app.'), findsOneWidget);
  });
}
