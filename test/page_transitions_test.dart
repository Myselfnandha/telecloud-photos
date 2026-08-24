import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:telecloud_photos/core/di/providers.dart';
import 'package:telecloud_photos/shared/navigation/page_transitions.dart';
import 'package:telecloud_photos/shared/navigation/transition_preference_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PageTransitionStyle enum tests', () {
    test('fromString parses correctly and defaults to fadeSlideUp', () {
      expect(
        PageTransitionStyle.fromString('sharedAxis'),
        PageTransitionStyle.sharedAxis,
      );
      expect(
        PageTransitionStyle.fromString('cupertinoSlide'),
        PageTransitionStyle.cupertinoSlide,
      );
      expect(
        PageTransitionStyle.fromString('fadeSlideUp'),
        PageTransitionStyle.fadeSlideUp,
      );
      expect(
        PageTransitionStyle.fromString('unknown_value'),
        PageTransitionStyle.fadeSlideUp,
      );
      expect(
        PageTransitionStyle.fromString(null),
        PageTransitionStyle.fadeSlideUp,
      );
    });

    test('toPrefString returns exact strings', () {
      expect(PageTransitionStyle.fadeSlideUp.toPrefString(), 'fadeSlideUp');
      expect(PageTransitionStyle.sharedAxis.toPrefString(), 'sharedAxis');
      expect(PageTransitionStyle.cupertinoSlide.toPrefString(), 'cupertinoSlide');
    });

    test('displayName and description are non-empty', () {
      for (final style in PageTransitionStyle.values) {
        expect(style.displayName.isNotEmpty, isTrue);
        expect(style.description.isNotEmpty, isTrue);
      }
    });
  });

  group('PageTransitionNotifier tests', () {
    test('loads from SharedPreferences and persists updates', () async {
      SharedPreferences.setMockInitialValues({
        'telecloud_transition_style': 'cupertinoSlide',
      });
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );

      final initial = container.read(pageTransitionProvider);
      expect(initial, PageTransitionStyle.cupertinoSlide);

      await container
          .read(pageTransitionProvider.notifier)
          .setTransitionStyle(PageTransitionStyle.sharedAxis);

      expect(container.read(pageTransitionProvider), PageTransitionStyle.sharedAxis);
      expect(prefs.getString('telecloud_transition_style'), 'sharedAxis');
    });
  });

  group('buildTransitionPage router tests', () {
    testWidgets('renders pages with custom transitions via GoRouter', (
      tester,
    ) async {
      final router = GoRouter(
        initialLocation: '/test',
        routes: [
          GoRoute(
            path: '/test',
            pageBuilder: (context, state) => buildTransitionPage(
              context: context,
              state: state,
              child: const Text('Hello World'),
              style: PageTransitionStyle.fadeSlideUp,
            ),
          ),
          GoRoute(
            path: '/viewer',
            pageBuilder: (context, state) => buildViewerTransitionPage(
              context: context,
              state: state,
              child: const Text('Viewer Page'),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hello World'), findsOneWidget);

      router.go('/viewer');
      await tester.pumpAndSettle();

      expect(find.text('Viewer Page'), findsOneWidget);
    });
  });
}
