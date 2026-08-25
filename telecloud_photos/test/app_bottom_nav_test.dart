import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telecloud_photos/shared/widgets/app_bottom_nav.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppBottomNav widget tests', () {
    testWidgets('renders all 4 tabs and responds to tap', (tester) async {
      int? tappedIndex;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: AppBottomNav(
              currentIndex: 0,
              onTap: (index) {
                tappedIndex = index;
              },
            ),
          ),
        ),
      );

      expect(find.text('Photos'), findsOneWidget);
      expect(find.text('Library'), findsOneWidget);
      expect(find.text('Uploads'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);

      await tester.tap(find.text('Library'));
      await tester.pumpAndSettle();

      expect(tappedIndex, 1);
    });
  });
}
