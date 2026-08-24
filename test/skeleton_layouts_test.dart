import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telecloud_photos/shared/widgets/skeleton_layouts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Skeleton Layouts widget tests', () {
    testWidgets('TimelineSkeletonGrid renders without errors', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TimelineSkeletonGrid(sectionCount: 2),
          ),
        ),
      );

      expect(find.byType(TimelineSkeletonGrid), findsOneWidget);
      expect(find.byType(SkeletonBone), findsWidgets);
    });

    testWidgets('AlbumListSkeleton renders without errors', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AlbumListSkeleton(itemCount: 4),
          ),
        ),
      );

      expect(find.byType(AlbumListSkeleton), findsOneWidget);
      expect(find.byType(SkeletonBone), findsWidgets);
    });

    testWidgets('SearchResultsSkeleton renders without errors', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SearchResultsSkeleton(),
          ),
        ),
      );

      expect(find.byType(SearchResultsSkeleton), findsOneWidget);
      expect(find.byType(SkeletonBone), findsWidgets);
    });
  });
}
