import 'dart:convert';

class MediaMetadata {
  final String app;
  final int version;
  final String filename;
  final DateTime capturedAt;
  final int? fileSizeBytes;
  final int? width;
  final int? height;
  final double? latitude;
  final double? longitude;
  final String? album;

  MediaMetadata({
    this.app = 'telecloud',
    this.version = 1,
    required this.filename,
    required this.capturedAt,
    this.fileSizeBytes,
    this.width,
    this.height,
    this.latitude,
    this.longitude,
    this.album,
  });

  Map<String, dynamic> toJson() => {
    'app': app,
    'v': version,
    'filename': filename,
    'captured': capturedAt.toIso8601String(),
    if (fileSizeBytes != null) 'size': fileSizeBytes,
    if (width != null) 'width': width,
    if (height != null) 'height': height,
    if (latitude != null) 'lat': latitude,
    if (longitude != null) 'lng': longitude,
    if (album != null) 'album': album,
  };

  String encode() => jsonEncode(toJson());

  static MediaMetadata? decode(String text) {
    try {
      final map = jsonDecode(text) as Map<String, dynamic>;
      if (map['app'] != 'telecloud') return null;
      return MediaMetadata(
        app: map['app'] as String,
        version: map['v'] as int? ?? 1,
        filename: map['filename'] as String,
        capturedAt: DateTime.parse(map['captured'] as String),
        fileSizeBytes: map['size'] as int?,
        width: map['width'] as int?,
        height: map['height'] as int?,
        latitude: (map['lat'] as num?)?.toDouble(),
        longitude: (map['lng'] as num?)?.toDouble(),
        album: map['album'] as String?,
      );
    } catch (_) {
      return null;
    }
  }
}
