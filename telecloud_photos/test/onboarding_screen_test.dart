import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:telecloud_photos/features/auth/screens/onboarding_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OnboardingScreen widget tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('renders first page elements correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: OnboardingScreen(),
        ),
      );

      expect(find.text('TeleCloud'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
      expect(find.text('SMART TIMELINE'), findsOneWidget);
      expect(find.text('Your Photos,\nYour Cloud'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
    });

    testWidgets('navigates to next pages and shows Get Started on last page', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: OnboardingScreen(),
        ),
      );

      // Page 1 -> Page 2
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('UNLIMITED & FREE'), findsOneWidget);
      expect(find.text('Unlimited Telegram\nCloud Backup'), findsOneWidget);

      // Page 2 -> Page 3
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('COMPLETE CONTROL'), findsOneWidget);
      expect(find.text('Privacy-First &\nTotal Control'), findsOneWidget);
      expect(find.text('Get Started'), findsOneWidget);
    });
  });
}
