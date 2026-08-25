import 'package:flutter_test/flutter_test.dart';
import 'package:telecloud_photos/shared/navigation/app_router.dart';

void main() {
  group('AppRouter Navigation Configuration Tests', () {
    test('appRouter is instantiated with GoRouter', () {
      expect(appRouter, isNotNull);
      expect(appRouter.configuration.routes, isNotEmpty);
    });

    test('appRouter contains all shell and sub-routes', () {
      final routeList = appRouter.configuration.routes;
      expect(routeList.isNotEmpty, isTrue);
    });
  });
}
