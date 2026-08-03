// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:nutrileaf/main.dart';
import 'package:nutrileaf/services/settings_service.dart';

void main() {
  testWidgets('NutriLeafApp smoke test', (WidgetTester tester) async {
    // Build our app wrapped in the required SettingsService provider.
    final settingsService = SettingsService();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: settingsService,
        child: const NutriLeafApp(),
      ),
    );

    // Verify that our app shows the NutriLeaf title on splash screen.
    expect(find.text('NutriLeaf'), findsOneWidget);

    // Settle splash screen transition timer (3 seconds)
    await tester.pump(const Duration(seconds: 4));
  });
}
