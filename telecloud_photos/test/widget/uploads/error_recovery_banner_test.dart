import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telecloud_photos/features/uploads/widgets/error_recovery_banner.dart';

void main() {
  group('ErrorRecoveryBanner Widget Tests', () {
    testWidgets('1. Renders nothing when failedCount is 0', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorRecoveryBanner(
              failedCount: 0,
              onRetryAll: () {},
              onDismiss: () {},
            ),
          ),
        ),
      );

      expect(find.text('Retry All'), findsNothing);
    });

    testWidgets(
        '2. Renders warning banner and responds to retry-all and dismiss',
        (tester) async {
      bool retryCalled = false;
      bool dismissCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorRecoveryBanner(
              failedCount: 3,
              onRetryAll: () => retryCalled = true,
              onDismiss: () => dismissCalled = true,
            ),
          ),
        ),
      );

      expect(find.text('3 uploads failed'), findsOneWidget);
      expect(find.text('Retry All'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);

      await tester.tap(find.text('Retry All'));
      expect(retryCalled, isTrue);

      await tester.tap(find.byIcon(Icons.close));
      expect(dismissCalled, isTrue);
    });
  });
}
