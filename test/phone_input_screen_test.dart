import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:telecloud_photos/features/auth/screens/phone_input_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PhoneInputScreen Validation Tests', () {
    testWidgets('validation does not show error for 1-9 digits; enables at 10 digits', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: PhoneInputScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find the phone text input field
      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);

      // 1. Enter 5 digits (partial input)
      await tester.enterText(textField, '98765');
      await tester.pumpAndSettle();

      // Ensure NO error is shown while typing fewer than 10 digits
      expect(find.textContaining('Invalid number'), findsNothing);
      expect(find.textContaining('minimum 10 digits'), findsNothing);

      // Verify Continue button is disabled
      final continueButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Continue'),
      );
      expect(continueButton.onPressed, isNull);

      // 2. Complete the 10 digits
      await tester.enterText(textField, '9876543210');
      await tester.pumpAndSettle();

      // Ensure no error is shown and checkmark appears
      expect(find.textContaining('Invalid number'), findsNothing);
      expect(find.textContaining('Phone number is too long'), findsNothing);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

      // Verify Continue button is now enabled
      final enabledButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Continue'),
      );
      expect(enabledButton.onPressed, isNotNull);

      // 3. Enter more than 15 digits
      await tester.enterText(textField, '9876543210123456');
      await tester.pumpAndSettle();

      // Ensure validation error is displayed
      expect(find.text('Phone number is too long (max 15 digits)'), findsOneWidget);

      // Verify Continue button is disabled
      final disabledButtonAfterOverlength = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Continue'),
      );
      expect(disabledButtonAfterOverlength.onPressed, isNull);
    });
  });
}
