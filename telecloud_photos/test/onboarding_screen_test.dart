import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:telecloud_photos/features/auth/screens/onboarding_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OnboardingScreen Material 3 Expressive widget tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('renders all M3 Expressive Onboarding & Auth elements correctly', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: OnboardingScreen(),
        ),
      );

      // App Bar title
      expect(find.text('TeleCloud Photos'), findsOneWidget);

      // Filled card headline
      expect(find.text('Unlimited Private Photo Cloud'), findsOneWidget);

      // Chip group
      expect(find.text('Unlimited Storage'), findsOneWidget);
      expect(find.text('Zero Compression'), findsOneWidget);
      expect(find.text('E2EE Privacy'), findsOneWidget);

      // Text field
      expect(find.text('Telegram Phone Number'), findsOneWidget);

      // Buttons
      expect(find.text('Continue with Telegram Code'), findsOneWidget);
      expect(find.text('Enter Telegram API ID & Hash Key'), findsOneWidget);

      // Caption
      expect(
        find.text('Instant setup • Powered by TDLib & MTProto Client'),
        findsOneWidget,
      );
    });
  });
}
