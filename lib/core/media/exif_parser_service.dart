import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:photo_manager/photo_manager.dart';
import '../utils/telecloud_logger.dart';

class ExifMetadata {
  final String? cameraMake;
  final String? cameraModel;
  final String? lensModel;
  final String? focalLength;
  final String? fNumber;
  final String? exposureTime;
  final String? iso;
  final bool? flashFired;
  final String? exposureBias;
  final double? latitude;
  final double? longitude;
  final double? altitude;
  final int? width;
  final int? height;
  final double? megapixels;
  final int? fileSizeBytes;
  final String? mimeType;
  final DateTime? dateTimeOriginal;
  final String? software;

  const ExifMetadata({
    this.cameraMake,
    this.cameraModel,
    this.lensModel,
    this.focalLength,
    this.fNumber,
    this.exposureTime,
    this.iso,
    this.flashFired,
    this.exposureBias,
    this.latitude,
    this.longitude,
    this.altitude,
    this.width,
    this.height,
    this.megapixels,
    this.fileSizeBytes,
    this.mimeType,
    this.dateTimeOriginal,
    this.software,
  });

  bool get hasCameraSpecs =>
      cameraModel != null ||
      cameraMake != null ||
      fNumber != null ||
      exposureTime != null ||
      iso != null ||
      focalLength != null;

  bool get hasLocation => latitude != null && longitude != null;

  String get formattedCameraTitle {
    if (cameraMake != null && cameraModel != null) {
      if (cameraModel!.toLowerCase().contains(cameraMake!.toLowerCase())) {
        return cameraModel!;
      }
      return '$cameraMake $cameraModel';
    }
    return cameraModel ?? cameraMake ?? 'Unknown Camera';
  }

  String get formattedResolution {
    if (width != null && height != null) {
      final mp =
          megapixels != null ? '${megapixels!.toStringAsFixed(1)} MP • ' : '';
      return '$mp$width × $height';
    }
    return 'Unknown Resolution';
  }

  String get formattedFileSize {
    if (fileSizeBytes == null || fileSizeBytes! <= 0) return 'Unknown Size';
    if (fileSizeBytes! >= 1024 * 1024 * 1024) {
      return '${(fileSizeBytes! / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
    if (fileSizeBytes! >= 1024 * 1024) {
      return '${(fileSizeBytes! / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(fileSizeBytes! / 1024).toStringAsFixed(1)} KB';
  }
}

class ExifParserService {
  static final Map<String, ExifMetadata> _cache = {};

  static Future<ExifMetadata> parseAsset(AssetEntity asset) async {
    final cacheKey = 'asset_${asset.id}';
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    try {
      final lat = asset.latitude != 0.0 ? asset.latitude : null;
      final lng = asset.longitude != 0.0 ? asset.longitude : null;

      final file = await asset.file;
      ExifMetadata fileExif = const ExifMetadata();
      if (file != null && await file.exists()) {
        fileExif = await parseFile(file);
      }

      final w = asset.width > 0 ? asset.width : fileExif.width;
      final h = asset.height > 0 ? asset.height : fileExif.height;
      final mp = (w != null && h != null && w > 0 && h > 0)
          ? (w * h) / 1000000.0
          : fileExif.megapixels;

      final merged = ExifMetadata(
        cameraMake: fileExif.cameraMake,
        cameraModel: fileExif.cameraModel,
        lensModel: fileExif.lensModel,
        focalLength: fileExif.focalLength,
        fNumber: fileExif.fNumber,
        exposureTime: fileExif.exposureTime,
        iso: fileExif.iso,
        flashFired: fileExif.flashFired,
        exposureBias: fileExif.exposureBias,
        latitude: lat ?? fileExif.latitude,
        longitude: lng ?? fileExif.longitude,
        altitude: fileExif.altitude,
        width: w,
        height: h,
        megapixels: mp,
        fileSizeBytes: fileExif.fileSizeBytes ??
            (file != null ? await file.length() : null),
        mimeType: asset.mimeType ?? fileExif.mimeType,
        dateTimeOriginal: asset.createDateTime,
        software: fileExif.software,
      );

      _cache[cacheKey] = merged;
      return merged;
    } catch (e) {
      TeleCloudLogger.log(
          'EXIF', 'Failed to parse EXIF for asset ${asset.id}: $e');
      return ExifMetadata(
        width: asset.width,
        height: asset.height,
        dateTimeOriginal: asset.createDateTime,
      );
    }
  }

  static Future<ExifMetadata> parseFile(File file) async {
    final path = file.path;
    if (_cache.containsKey(path)) {
      return _cache[path]!;
    }

    try {
      final length = await file.length();
      // Read first 64KB where EXIF headers are located
      final headerBytes = await file.openRead(0, min(length, 65536)).first;
      final parsed = _parseBytes(Uint8List.fromList(headerBytes), length);
      _cache[path] = parsed;
      return parsed;
    } catch (e) {
      TeleCloudLogger.log(
          'EXIF', 'Failed to parse EXIF from file ${file.path}: $e');
      final length = await file.length().catchError((_) => 0);
      return ExifMetadata(fileSizeBytes: length);
    }
  }

  static ExifMetadata _parseBytes(Uint8List bytes, int totalFileSize) {
    if (bytes.length < 12) {
      return ExifMetadata(fileSizeBytes: totalFileSize);
    }

    // Check for JPEG SOI marker (0xFFD8)
    if (bytes[0] == 0xFF && bytes[1] == 0xD8) {
      return _parseJpegExif(bytes, totalFileSize);
    }

    return ExifMetadata(fileSizeBytes: totalFileSize);
  }

  static ExifMetadata _parseJpegExif(Uint8List bytes, int totalFileSize) {
    int offset = 2;
    while (offset + 4 < bytes.length) {
      if (bytes[offset] != 0xFF) break;
      final marker = bytes[offset + 1];
      final length = (bytes[offset + 2] << 8) | bytes[offset + 3];

      // APP1 Marker for Exif (0xFFE1)
      if (marker == 0xE1 && offset + 4 + length <= bytes.length) {
        final exifHeader =
            String.fromCharCodes(bytes.sublist(offset + 4, offset + 8));
        if (exifHeader.startsWith('Exif')) {
          final tiffOffset = offset + 10;
          return _parseTiffHeader(bytes, tiffOffset, totalFileSize);
        }
      }

      offset += 2 + length;
    }

    return ExifMetadata(fileSizeBytes: totalFileSize);
  }

  static ExifMetadata _parseTiffHeader(
    Uint8List bytes,
    int tiffStart,
    int totalFileSize,
  ) {
    if (tiffStart + 8 > bytes.length) {
      return ExifMetadata(fileSizeBytes: totalFileSize);
    }

    final isLittleEndian =
        bytes[tiffStart] == 0x49 && bytes[tiffStart + 1] == 0x49; // 'II'
    final byteData = ByteData.sublistView(bytes);

    int read16(int pos) =>
        byteData.getUint16(pos, isLittleEndian ? Endian.little : Endian.big);
    int read32(int pos) =>
        byteData.getUint32(pos, isLittleEndian ? Endian.little : Endian.big);

    final ifd0Offset = tiffStart + read32(tiffStart + 4);
    if (ifd0Offset + 2 > bytes.length) {
      return ExifMetadata(fileSizeBytes: totalFileSize);
    }

    String? make;
    String? model;
    String? software;
    String? lensModel;
    String? focalLength;
    String? fNumber;
    String? exposureTime;
    String? iso;
    bool? flashFired;
    String? exposureBias;
    double? latitude;
    double? longitude;
    double? altitude;
    int? width;
    int? height;
    DateTime? dateTimeOriginal;

    int? exifIfdOffset;
    int? gpsIfdOffset;

    void parseIfd(int offset, bool isGps) {
      if (offset + 2 > bytes.length) return;
      final numEntries = read16(offset);
      int cur = offset + 2;

      for (int i = 0; i < numEntries; i++) {
        if (cur + 12 > bytes.length) break;
        final tag = read16(cur);
        final type = read16(cur + 2);
        final count = read32(cur + 4);
        final valueOffset = tiffStart + read32(cur + 8);

        if (!isGps) {
          switch (tag) {
            case 0x010F: // Make
              make = _readString(bytes, type, count, cur + 8, valueOffset);
              break;
            case 0x0110: // Model
              model = _readString(bytes, type, count, cur + 8, valueOffset);
              break;
            case 0x0131: // Software
              software = _readString(bytes, type, count, cur + 8, valueOffset);
              break;
            case 0x0100: // ImageWidth
              width = _readInt(read16, read32, type, cur + 8);
              break;
            case 0x0101: // ImageHeight
              height = _readInt(read16, read32, type, cur + 8);
              break;
            case 0x8769: // Exif IFD Pointer
              exifIfdOffset = tiffStart + read32(cur + 8);
              break;
            case 0x8825: // GPS IFD Pointer
              gpsIfdOffset = tiffStart + read32(cur + 8);
              break;
            case 0x829A: // ExposureTime
              exposureTime =
                  _readRationalFraction(byteData, isLittleEndian, valueOffset);
              break;
            case 0x829D: // FNumber
              fNumber = _readFNumber(byteData, isLittleEndian, valueOffset);
              break;
            case 0x8827: // ISO
              iso = 'ISO ${_readInt(read16, read32, type, cur + 8)}';
              break;
            case 0x920A: // FocalLength
              focalLength =
                  _readFocalLength(byteData, isLittleEndian, valueOffset);
              break;
            case 0xA434: // LensModel
              lensModel = _readString(bytes, type, count, cur + 8, valueOffset);
              break;
            case 0x9209: // Flash
              final flashVal = _readInt(read16, read32, type, cur + 8);
              if (flashVal != null) flashFired = (flashVal & 1) == 1;
              break;
            case 0x9204: // ExposureBias
              exposureBias =
                  _readExposureBias(byteData, isLittleEndian, valueOffset);
              break;
          }
        } else {
          // GPS IFD
          if (tag == 0x0006 && valueOffset + 8 <= bytes.length) {
            // GPS Altitude
            final num = read32(valueOffset);
            final den = read32(valueOffset + 4);
            if (den > 0) altitude = num / den;
          }
        }

        cur += 12;
      }
    }

    parseIfd(ifd0Offset, false);
    if (exifIfdOffset != null) parseIfd(exifIfdOffset!, false);
    if (gpsIfdOffset != null) parseIfd(gpsIfdOffset!, true);

    final mp = (width != null && height != null && width! > 0 && height! > 0)
        ? (width! * height!) / 1000000.0
        : null;

    return ExifMetadata(
      cameraMake: make?.trim(),
      cameraModel: model?.trim(),
      lensModel: lensModel?.trim(),
      focalLength: focalLength,
      fNumber: fNumber,
      exposureTime: exposureTime,
      iso: iso,
      flashFired: flashFired,
      exposureBias: exposureBias,
      latitude: latitude,
      longitude: longitude,
      altitude: altitude,
      width: width,
      height: height,
      megapixels: mp,
      fileSizeBytes: totalFileSize,
      software: software?.trim(),
      dateTimeOriginal: dateTimeOriginal,
    );
  }

  static String? _readString(
    Uint8List bytes,
    int type,
    int count,
    int inlineOffset,
    int valueOffset,
  ) {
    if (count <= 0) return null;
    final srcOffset = count <= 4 ? inlineOffset : valueOffset;
    if (srcOffset + count > bytes.length) return null;
    return String.fromCharCodes(
      bytes.sublist(srcOffset, srcOffset + count),
    ).replaceAll('\x00', '').trim();
  }

  static int? _readInt(
    int Function(int) read16,
    int Function(int) read32,
    int type,
    int offset,
  ) {
    if (type == 3) return read16(offset);
    if (type == 4) return read32(offset);
    return null;
  }

  static String? _readRationalFraction(
    ByteData byteData,
    bool isLittleEndian,
    int offset,
  ) {
    if (offset + 8 > byteData.lengthInBytes) return null;
    final num =
        byteData.getUint32(offset, isLittleEndian ? Endian.little : Endian.big);
    final den = byteData.getUint32(
        offset + 4, isLittleEndian ? Endian.little : Endian.big);
    if (den == 0) return null;
    if (num < den && num > 0) {
      final inv = (den / num).round();
      return '1/${inv}s';
    }
    return '${(num / den).toStringAsFixed(1)}s';
  }

  static String? _readFNumber(
    ByteData byteData,
    bool isLittleEndian,
    int offset,
  ) {
    if (offset + 8 > byteData.lengthInBytes) return null;
    final num =
        byteData.getUint32(offset, isLittleEndian ? Endian.little : Endian.big);
    final den = byteData.getUint32(
        offset + 4, isLittleEndian ? Endian.little : Endian.big);
    if (den == 0) return null;
    final val = num / den;
    return 'f/${val.toStringAsFixed(val >= 10 ? 0 : 1)}';
  }

  static String? _readFocalLength(
    ByteData byteData,
    bool isLittleEndian,
    int offset,
  ) {
    if (offset + 8 > byteData.lengthInBytes) return null;
    final num =
        byteData.getUint32(offset, isLittleEndian ? Endian.little : Endian.big);
    final den = byteData.getUint32(
        offset + 4, isLittleEndian ? Endian.little : Endian.big);
    if (den == 0) return null;
    final val = num / den;
    return '${val.toStringAsFixed(val >= 10 ? 0 : 1)}mm';
  }

  static String? _readExposureBias(
    ByteData byteData,
    bool isLittleEndian,
    int offset,
  ) {
    if (offset + 8 > byteData.lengthInBytes) return null;
    final num =
        byteData.getInt32(offset, isLittleEndian ? Endian.little : Endian.big);
    final den = byteData.getInt32(
        offset + 4, isLittleEndian ? Endian.little : Endian.big);
    if (den == 0) return null;
    final val = num / den;
    return '${val >= 0 ? '+' : ''}${val.toStringAsFixed(1)} EV';
  }

  static void clearCache() {
    _cache.clear();
  }
}
