import 'package:flutter_test/flutter_test.dart';
import 'package:telecloud_photos/core/utils/telegram_credential_parser.dart';

void main() {
  group('TelegramCredentialParser Tests', () {
    test('1. Parses raw web copy from my.telegram.org', () {
      const input = '''
App Configuration
App api_id: 28492019
App api_hash: 7d6c8b9a1e2f3a4b5c6d7e8f90123456
Short name: telecloud
''';
      final result = TelegramCredentialParser.parse(input);
      expect(result.isValid, isTrue);
      expect(result.apiId, 28492019);
      expect(result.apiHash, '7d6c8b9a1e2f3a4b5c6d7e8f90123456');
    });

    test('2. Parses .env format', () {
      const input = '''
TELEGRAM_API_ID=1928374
TELEGRAM_API_HASH=a1b2c3d4e5f67890abcdef1234567890
''';
      final result = TelegramCredentialParser.parse(input);
      expect(result.isValid, isTrue);
      expect(result.apiId, 1928374);
      expect(result.apiHash, 'a1b2c3d4e5f67890abcdef1234567890');
    });

    test('3. Parses JSON format', () {
      const input =
          '{"api_id": 9876543, "api_hash": "b18441a1b608e3cdeec510d3f026fb29"}';
      final result = TelegramCredentialParser.parse(input);
      expect(result.isValid, isTrue);
      expect(result.apiId, 9876543);
      expect(result.apiHash, 'b18441a1b608e3cdeec510d3f026fb29');
    });

    test('4. Parses raw space-separated tokens', () {
      const input = '2891048 7d6c8b9a1e2f3a4b5c6d7e8f90123456';
      final result = TelegramCredentialParser.parse(input);
      expect(result.isValid, isTrue);
      expect(result.apiId, 2891048);
      expect(result.apiHash, '7d6c8b9a1e2f3a4b5c6d7e8f90123456');
    });

    test('5. Parses individual standalone hash or ID', () {
      final singleId = TelegramCredentialParser.parse('2948201');
      expect(singleId.apiId, 2948201);
      expect(singleId.apiHash, isNull);

      final singleHash =
          TelegramCredentialParser.parse('8da85b0d5b1652522bc46057082da478');
      expect(singleHash.apiId, isNull);
      expect(singleHash.apiHash, '8da85b0d5b1652522bc46057082da478');
    });

    test('6. Handles empty or garbage text safely', () {
      final result =
          TelegramCredentialParser.parse('hello world this is not valid');
      expect(result.isValid, isFalse);
      expect(result.hasAny, isFalse);
    });
  });
}
