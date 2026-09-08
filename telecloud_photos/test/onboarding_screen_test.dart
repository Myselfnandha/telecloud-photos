import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
        const ProviderScope(
          child: MaterialApp(
            home: OnboardingScreen(),
          ),
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

      // Buttons
      expect(find.text('Connect Telegram Cloud'), findsOneWidget);
      expect(find.text('Enter Credentials Manually'), findsOneWidget);

      // Caption
      expect(
        find.text('Instant setup • Powered by TDLib & MTProto Client'),
        findsOneWidget,
      );
    });
  });
}
