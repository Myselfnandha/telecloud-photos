import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:telecloud_photos/core/cache/thumbnail_cache_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ThumbnailCacheService Tests', () {
    late ThumbnailCacheService cacheService;

    setUp(() {
      cacheService = ThumbnailCacheService();
      cacheService.clearMemory();
    });

    test('1. In-memory cache stores and retrieves bytes synchronously', () {
      final sampleBytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      cacheService.putInMemory('item_1', sampleBytes);

      final retrieved = cacheService.getFromMemory('item_1');
      expect(retrieved, isNotNull);
      expect(retrieved, equals(sampleBytes));
    });

    test('2. getFromMemory returns null for non-existent items', () {
      final nonExistent = cacheService.getFromMemory('unknown_item');
      expect(nonExistent, isNull);
    });

    test(
      '3. Fallback Google Photos generator creates valid PNG byte stream',
      () async {
        final bytes = await cacheService.getThumbnail(id: 'gp_photo_test_99');
        expect(bytes, isNotNull);
        expect(bytes!.length, greaterThan(16));

        // Validate PNG magic header: 0x89, 'P', 'N', 'G', 0x0D, 0x0A, 0x1A, 0x0A
        expect(bytes[0], 0x89);
        expect(bytes[1], 0x50); // 'P'
        expect(bytes[2], 0x4E); // 'N'
        expect(bytes[3], 0x47); // 'G'
        expect(bytes[4], 0x0D);
        expect(bytes[5], 0x0A);
        expect(bytes[6], 0x1A);
        expect(bytes[7], 0x0A);
      },
    );

    test('4. In-memory cache evicts oldest entries beyond max limit', () {
      // Put 601 entries to test LRU eviction of oldest
      for (int i = 0; i <= 600; i++) {
        cacheService.putInMemory('item_$i', Uint8List.fromList([i % 256]));
      }

      // Oldest item 'item_0' should be evicted
      expect(cacheService.getFromMemory('item_0'), isNull);
      // Latest item 'item_600' should exist
      expect(cacheService.getFromMemory('item_600'), isNotNull);
    });

    test('5. clearMemory resets in-memory cache', () {
      cacheService.putInMemory('persist_test', Uint8List.fromList([42]));
      expect(cacheService.getFromMemory('persist_test'), isNotNull);

      cacheService.clearMemory();
      expect(cacheService.getFromMemory('persist_test'), isNull);
    });
  });
}
