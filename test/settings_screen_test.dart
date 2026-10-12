import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_skill_exchange/screens/settings/settings_screen.dart';

void main() {
  testWidgets('SettingsScreen renders all sections without assertion errors', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: SettingsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Settings & Preferences'), findsOneWidget);
    expect(find.text('Account & Identity'), findsOneWidget);
    expect(find.text('Appearance & Theme'), findsOneWidget);
    expect(find.text('Privacy & Proximity'), findsOneWidget);
    expect(find.text('Notifications & Alerts'), findsOneWidget);
    expect(find.text('Learning Goals & Style'), findsOneWidget);
    expect(find.text('Security'), findsOneWidget);
    expect(find.text('About Local Skill Exchange'), findsOneWidget);
    expect(find.text('Account Actions'), findsOneWidget);
  });
}
