import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:path/path.dart' as p;

class ThumbnailCacheService {
  static final ThumbnailCacheService _instance =
      ThumbnailCacheService._internal();
  factory ThumbnailCacheService() => _instance;
  ThumbnailCacheService._internal();

  // In-memory LRU cache: keeps up to 600 decoded thumbnail byte arrays
  final LinkedHashMap<String, Uint8List> _memoryCache =
      LinkedHashMap<String, Uint8List>();
  static const int _maxMemoryEntries = 600;

  // In-flight futures deduplication to prevent redundant concurrent fetches
  final Map<String, Future<Uint8List?>> _inFlightFetches = {};

  Directory? _diskCacheDir;

  Future<void> init() async {
    try {
      final docDir = await getApplicationDocumentsDirectory();
      _diskCacheDir = Directory(p.join(docDir.path, 'thumbnails'));
      if (!await _diskCacheDir!.exists()) {
        await _diskCacheDir!.create(recursive: true);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[ThumbnailCacheService] Init error: $e');
    }
  }

  Uint8List? getFromMemory(String id) {
    if (_memoryCache.containsKey(id)) {
      final bytes = _memoryCache.remove(id)!;
      _memoryCache[id] = bytes; // Move to end (most recently used)
      return bytes;
    }
    return null;
  }

  void putInMemory(String id, Uint8List bytes) {
    if (_memoryCache.containsKey(id)) {
      _memoryCache.remove(id);
    } else if (_memoryCache.length >= _maxMemoryEntries) {
      _memoryCache.remove(_memoryCache.keys.first); // Remove oldest
    }
    _memoryCache[id] = bytes;
  }

  Future<Uint8List?> getThumbnail({
    required String id,
    String? diskPath,
    bool isVideo = false,
  }) async {
    // 1. Check in-memory LRU cache (0ms)
    final mem = getFromMemory(id);
    if (mem != null) return mem;

    // 2. Check in-flight request to avoid duplicate parallel fetches
    if (_inFlightFetches.containsKey(id)) {
      return _inFlightFetches[id];
    }

    final future = _loadThumbnailInternal(
      id: id,
      diskPath: diskPath,
      isVideo: isVideo,
    );
    _inFlightFetches[id] = future;

    try {
      final result = await future;
      return result;
    } finally {
      _inFlightFetches.remove(id);
    }
  }

  Future<Uint8List?> _loadThumbnailInternal({
    required String id,
    String? diskPath,
    bool isVideo = false,
  }) async {
    // Check provided disk path
    if (diskPath != null && diskPath.isNotEmpty) {
      final file = File(diskPath);
      if (await file.exists()) {
        try {
          final bytes = await file.readAsBytes();
          if (bytes.isNotEmpty) {
            putInMemory(id, bytes);
            return bytes;
          }
        } catch (_) {}
      }
    }

    // Check disk cache directory
    if (_diskCacheDir == null) {
      await init();
    }

    final safeId = id.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    if (_diskCacheDir != null) {
      final cachedFile = File(p.join(_diskCacheDir!.path, '$safeId.jpg'));
      if (await cachedFile.exists()) {
        try {
          final bytes = await cachedFile.readAsBytes();
          if (bytes.isNotEmpty) {
            putInMemory(id, bytes);
            return bytes;
          }
        } catch (_) {}
      }
    }

    // Load from PhotoManager AssetEntity for local device items
    if (!id.startsWith('tg_') && !id.startsWith('gp_')) {
      try {
        final asset = await AssetEntity.fromId(id);
        if (asset != null) {
          final bytes = await asset.thumbnailDataWithSize(
            const ThumbnailSize.square(256),
          );
          if (bytes != null && bytes.isNotEmpty) {
            putInMemory(id, bytes);
            // Asynchronously save to disk cache if available
            if (_diskCacheDir != null) {
              final cachedFile = File(
                p.join(_diskCacheDir!.path, '$safeId.jpg'),
              );
              cachedFile.writeAsBytes(bytes).catchError((_) => cachedFile);
            }
            return bytes;
          }
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[ThumbnailCacheService] Error fetching asset $id: $e');
        }
      }
    } else if (id.startsWith('gp_')) {
      final bytes = _generateValidGooglePng(id);
      putInMemory(id, bytes);
      return bytes;
    }

    return null;
  }

  Uint8List _generateValidGooglePng(String seedId) {
    final colors = [
      [0x42, 0x85, 0xF4, 0xFF], // Google Blue
      [0x34, 0xA8, 0x53, 0xFF], // Google Green
      [0xFB, 0xBC, 0x05, 0xFF], // Google Yellow
      [0xEA, 0x43, 0x35, 0xFF], // Google Red
    ];
    final colorIdx = seedId.hashCode.abs() % colors.length;
    final r = colors[colorIdx][0];
    final g = colors[colorIdx][1];
    final b = colors[colorIdx][2];

    const width = 64;
    const height = 64;
    final rawData = <int>[];

    for (int y = 0; y < height; y++) {
      rawData.add(0);
      for (int x = 0; x < width; x++) {
        final mixR = ((r * (width - x) + 0x1A * x) ~/ width).clamp(0, 255);
        final mixG = ((g * (height - y) + 0x1A * y) ~/ height).clamp(0, 255);
        final mixB = ((b * (x + y)) ~/ (width + height)).clamp(0, 255);
        rawData.addAll([mixR, mixG, mixB, 0xFF]);
      }
    }

    final compressed = zlib.encode(rawData);
    final pngBytes = BytesBuilder();
    pngBytes.add([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);

    final ihdrData = ByteData(13)
      ..setUint32(0, width)
      ..setUint32(4, height)
      ..setUint8(8, 8)
      ..setUint8(9, 6)
      ..setUint8(10, 0)
      ..setUint8(11, 0)
      ..setUint8(12, 0);

    _writePngChunk(pngBytes, 'IHDR', ihdrData.buffer.asUint8List());
    _writePngChunk(pngBytes, 'IDAT', Uint8List.fromList(compressed));
    _writePngChunk(pngBytes, 'IEND', Uint8List(0));

    return pngBytes.toBytes();
  }

  void _writePngChunk(BytesBuilder builder, String type, Uint8List data) {
    final typeBytes = utf8.encode(type);
    final lengthData = ByteData(4)..setUint32(0, data.length);
    builder.add(lengthData.buffer.asUint8List());
    builder.add(typeBytes);
    builder.add(data);

    final crcInput = Uint8List.fromList([...typeBytes, ...data]);
    int crc = 0xFFFFFFFF;
    for (final byte in crcInput) {
      crc ^= byte;
      for (int k = 0; k < 8; k++) {
        crc = (crc & 1 != 0) ? (0xEDB88320 ^ (crc >>> 1)) : (crc >>> 1);
      }
    }
    crc = (crc ^ 0xFFFFFFFF) & 0xFFFFFFFF;
    final crcData = ByteData(4)..setUint32(0, crc);
    builder.add(crcData.buffer.asUint8List());
  }

  void clearMemory() {
    _memoryCache.clear();
  }
}
