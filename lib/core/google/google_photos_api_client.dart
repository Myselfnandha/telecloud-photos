import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'google_auth_service.dart';

class GooglePhotosMediaItem {
  final String id;
  final String filename;
  final String? description;
  final String baseUrl;
  final String mimeType;
  final DateTime creationTime;
  final int? width;
  final int? height;
  final double? latitude;
  final double? longitude;
  final String? albumId;
  final String? albumTitle;
  final int? fileSizeBytes;

  GooglePhotosMediaItem({
    required this.id,
    required this.filename,
    this.description,
    required this.baseUrl,
    required this.mimeType,
    required this.creationTime,
    this.width,
    this.height,
    this.latitude,
    this.longitude,
    this.albumId,
    this.albumTitle,
    this.fileSizeBytes,
  });

  bool get isVideo => mimeType.startsWith('video/');

  factory GooglePhotosMediaItem.fromJson(
    Map<String, dynamic> json, {
    String? albumId,
    String? albumTitle,
  }) {
    final metadata = json['mediaMetadata'] as Map<String, dynamic>? ?? {};
    final creationStr = metadata['creationTime'] as String?;
    final creation = creationStr != null
        ? DateTime.tryParse(creationStr) ?? DateTime.now()
        : DateTime.now();

    final widthStr = metadata['width'] as String?;
    final heightStr = metadata['height'] as String?;

    return GooglePhotosMediaItem(
      id: json['id'] as String? ?? '',
      filename: json['filename'] as String? ?? 'google_photo_${json['id']}.jpg',
      description: json['description'] as String?,
      baseUrl: json['baseUrl'] as String? ?? '',
      mimeType: json['mimeType'] as String? ?? 'image/jpeg',
      creationTime: creation,
      width: widthStr != null ? int.tryParse(widthStr) : null,
      height: heightStr != null ? int.tryParse(heightStr) : null,
      albumId: albumId,
      albumTitle: albumTitle,
    );
  }
}

class GooglePhotosAlbum {
  final String id;
  final String title;
  final int itemCount;
  final String? coverPhotoBaseUrl;

  GooglePhotosAlbum({
    required this.id,
    required this.title,
    required this.itemCount,
    this.coverPhotoBaseUrl,
  });

  factory GooglePhotosAlbum.fromJson(Map<String, dynamic> json) {
    final mediaItemsCount = json['mediaItemsCount'] as String?;
    return GooglePhotosAlbum(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Untitled Album',
      itemCount: mediaItemsCount != null
          ? int.tryParse(mediaItemsCount) ?? 0
          : 0,
      coverPhotoBaseUrl: json['coverPhotoBaseUrl'] as String?,
    );
  }
}

class GooglePhotosApiClient {
  static const String _apiBase = 'https://photoslibrary.googleapis.com/v1';
  final GoogleAuthService _authService;
  final http.Client _httpClient;

  GooglePhotosApiClient({
    required GoogleAuthService authService,
    http.Client? httpClient,
  }) : _authService = authService,
       _httpClient = httpClient ?? http.Client();

  Future<List<GooglePhotosMediaItem>> listMediaItems({
    int pageSize = 50,
    String? pageToken,
    DateTime? startDate,
    DateTime? endDate,
    String? albumId,
    String? albumTitle,
  }) async {
    final headers = await _authService.getAuthHeaders();
    if (headers.isEmpty) {
      debugPrint('[GooglePhotosApiClient] Unauthenticated call to listMediaItems');
      return [];
    }

    try {
      Uri url;
      http.Response response;

      if (albumId != null) {
        url = Uri.parse('$_apiBase/mediaItems:search');
        final bodyMap = <String, dynamic>{
          'pageSize': pageSize,
          'albumId': albumId,
        };
        if (pageToken != null) bodyMap['pageToken'] = pageToken;

        response = await _httpClient.post(
          url,
          headers: headers,
          body: jsonEncode(bodyMap),
        );
      } else if (startDate != null || endDate != null) {
        url = Uri.parse('$_apiBase/mediaItems:search');
        final bodyMap = <String, dynamic>{
          'pageSize': pageSize,
          'filters': {
            'dateFilter': {
              'ranges': [
                {
                  if (startDate != null)
                    'startDate': {
                      'year': startDate.year,
                      'month': startDate.month,
                      'day': startDate.day,
                    },
                  if (endDate != null)
                    'endDate': {
                      'year': endDate.year,
                      'month': endDate.month,
                      'day': endDate.day,
                    },
                },
              ],
            },
          },
        };
        if (pageToken != null) bodyMap['pageToken'] = pageToken;

        response = await _httpClient.post(
          url,
          headers: headers,
          body: jsonEncode(bodyMap),
        );
      } else {
        final queryParams = <String, String>{'pageSize': pageSize.toString()};
        if (pageToken != null) {
          queryParams['pageToken'] = pageToken;
        }
        url = Uri.parse(
          '$_apiBase/mediaItems',
        ).replace(queryParameters: queryParams);
        response = await _httpClient.get(url, headers: headers);
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final rawItems = data['mediaItems'] as List<dynamic>? ?? [];
        return rawItems
            .map(
              (item) => GooglePhotosMediaItem.fromJson(
                item as Map<String, dynamic>,
                albumId: albumId,
                albumTitle: albumTitle,
              ),
            )
            .toList();
      } else {
        debugPrint(
          '[GooglePhotosApiClient] API Error ${response.statusCode}: ${response.body}',
        );
        return [];
      }
    } catch (e) {
      debugPrint('[GooglePhotosApiClient] Exception in listMediaItems: $e');
      return [];
    }
  }

  Future<List<GooglePhotosAlbum>> listAlbums({
    int pageSize = 50,
    String? pageToken,
  }) async {
    final headers = await _authService.getAuthHeaders();
    if (headers.isEmpty) {
      debugPrint('[GooglePhotosApiClient] Unauthenticated call to listAlbums');
      return [];
    }

    final allAlbums = <GooglePhotosAlbum>[];

    try {
      final queryParams = <String, String>{'pageSize': pageSize.toString()};
      if (pageToken != null) {
        queryParams['pageToken'] = pageToken;
      }

      // 1. Fetch user created albums
      final url = Uri.parse(
        '$_apiBase/albums',
      ).replace(queryParameters: queryParams);
      final response = await _httpClient.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final rawAlbums = data['albums'] as List<dynamic>? ?? [];
        allAlbums.addAll(
          rawAlbums.map(
            (a) => GooglePhotosAlbum.fromJson(a as Map<String, dynamic>),
          ),
        );
      } else {
        debugPrint(
          '[GooglePhotosApiClient] listAlbums HTTP error: ${response.statusCode} - ${response.body}',
        );
      }

      // 2. Fetch shared albums
      try {
        final sharedUrl = Uri.parse(
          '$_apiBase/sharedAlbums',
        ).replace(queryParameters: queryParams);
        final sharedResponse = await _httpClient.get(
          sharedUrl,
          headers: headers,
        );
        if (sharedResponse.statusCode == 200) {
          final sharedData =
              jsonDecode(sharedResponse.body) as Map<String, dynamic>;
          final rawShared = sharedData['sharedAlbums'] as List<dynamic>? ?? [];
          final parsedShared = rawShared.map(
            (a) => GooglePhotosAlbum.fromJson(a as Map<String, dynamic>),
          );
          for (final sa in parsedShared) {
            if (!allAlbums.any((existing) => existing.id == sa.id)) {
              allAlbums.add(sa);
            }
          }
        }
      } catch (e) {
        debugPrint('[GooglePhotosApiClient] listSharedAlbums error: $e');
      }

      return allAlbums;
    } catch (e) {
      debugPrint('[GooglePhotosApiClient] Exception in listAlbums: $e');
      return [];
    }
  }

  Future<File> downloadMediaStream(
    GooglePhotosMediaItem item,
    String destinationPath, {
    Function(int received, int total)? onProgress,
  }) async {
    final destFile = File(destinationPath);
    if (!destFile.parent.existsSync()) {
      destFile.parent.createSync(recursive: true);
    }

    // Download URL: append '=d' for original bit-for-bit image, or '=dv' for original video
    final downloadUrl = item.baseUrl.isNotEmpty
        ? (item.isVideo ? '${item.baseUrl}=dv' : '${item.baseUrl}=d')
        : '';

    if (downloadUrl.isEmpty) {
      throw const HttpException('Google Photos media item has empty baseUrl');
    }

    final request = http.Request('GET', Uri.parse(downloadUrl));
    final authHeaders = await _authService.getAuthHeaders();
    if (authHeaders.isNotEmpty && authHeaders.containsKey('Authorization')) {
      request.headers['Authorization'] = authHeaders['Authorization']!;
    }

    final response = await _httpClient.send(request);
    if (response.statusCode != 200) {
      throw HttpException(
        'Failed to download Google Photos media ${item.id}: HTTP ${response.statusCode}',
      );
    }

    final total = response.contentLength ?? 0;
    int received = 0;

    final sink = destFile.openWrite();
    await response.stream.listen((chunk) {
      sink.add(chunk);
      received += chunk.length;
      if (onProgress != null) {
        onProgress(received, total);
      }
    }).asFuture();

    await sink.flush();
    await sink.close();

    return destFile;
  }
}
