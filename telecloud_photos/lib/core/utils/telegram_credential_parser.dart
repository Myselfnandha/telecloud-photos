class ParsedCredentials {
  final int? apiId;
  final String? apiHash;

  const ParsedCredentials({this.apiId, this.apiHash});

  bool get isValid =>
      (apiId != null && apiId! > 0) &&
      (apiHash != null && apiHash!.length >= 30);
  bool get hasAny => apiId != null || (apiHash != null && apiHash!.isNotEmpty);

  @override
  String toString() =>
      'ParsedCredentials(apiId: $apiId, apiHash: ${apiHash != null ? "***" : null})';
}

/// Universal multi-format parser for Telegram API credentials.
/// Supports:
/// - Raw copy from my.telegram.org (`App api_id: 12345678`, `App api_hash: 7d6c...`)
/// - .env format (`TELEGRAM_API_ID=...`, `TELEGRAM_API_HASH=...`)
/// - JSON format (`{"api_id": 12345, "api_hash": "abc..."}`)
/// - Whitespace / comma / colon separated tokens
/// - Standalone single IDs or Hashes
class TelegramCredentialParser {
  // Regex patterns for API ID
  static final RegExp _apiIdLabeledRegex = RegExp(
    r"""(?:api[-_]?id|app[-_]?api[-_]?id)\s*[:=]\s*["']?(\d{5,10})["']?""",
    caseSensitive: false,
  );

  // Regex patterns for API Hash (32-character hexadecimal)
  static final RegExp _apiHashLabeledRegex = RegExp(
    r"""(?:api[-_]?hash|app[-_]?api[-_]?hash)\s*[:=]\s*["']?([a-fA-F0-9]{30,36})["']?""",
    caseSensitive: false,
  );

  // Standalone 32-char hex string
  static final RegExp _standaloneHexRegex = RegExp(
    r'\b([a-fA-F0-9]{32})\b',
  );

  // Standalone 5 to 9 digit number
  static final RegExp _standaloneNumberRegex = RegExp(
    r'\b(\d{5,9})\b',
  );

  /// Parses text from clipboard or manual entry into [ParsedCredentials].
  static ParsedCredentials parse(String text) {
    if (text.trim().isEmpty) return const ParsedCredentials();

    final cleanText = text.trim();
    int? extractedId;
    String? extractedHash;

    // 1. Try labeled regex matching (e.g. "App api_id: 12345", "TELEGRAM_API_ID=12345")
    final idMatch = _apiIdLabeledRegex.firstMatch(cleanText);
    if (idMatch != null) {
      extractedId = int.tryParse(idMatch.group(1)!);
    }

    final hashMatch = _apiHashLabeledRegex.firstMatch(cleanText);
    if (hashMatch != null) {
      extractedHash = hashMatch.group(1)!.toLowerCase();
    }

    // 2. If hash was not found by label, look for a 32-character hex token
    if (extractedHash == null) {
      final hexMatch = _standaloneHexRegex.firstMatch(cleanText);
      if (hexMatch != null) {
        extractedHash = hexMatch.group(1)!.toLowerCase();
      }
    }

    // 3. If ID was not found by label, look for a standalone 5-9 digit number (that isn't part of the hash)
    if (extractedId == null) {
      // Remove the hash if present to avoid matching numbers inside the hash
      var textWithoutHash = cleanText;
      if (extractedHash != null) {
        textWithoutHash = textWithoutHash.replaceAll(extractedHash, '');
      }

      final numberMatches = _standaloneNumberRegex.allMatches(textWithoutHash);
      for (final match in numberMatches) {
        final parsed = int.tryParse(match.group(1)!);
        if (parsed != null && parsed > 10000) {
          extractedId = parsed;
          break;
        }
      }
    }

    return ParsedCredentials(
      apiId: extractedId,
      apiHash: extractedHash,
    );
  }
}
