import 'package:flutter_test/flutter_test.dart';
import 'package:telecloud_photos/core/telegram/channel_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ChannelManager — Folder Emoji & Auto-Topic Mapping', () {
    test('1. getFolderDisplayEmoji returns appropriate emoji for device albums', () {
      expect(ChannelManager.getFolderDisplayEmoji('Camera'), '📷');
      expect(ChannelManager.getFolderDisplayEmoji('DCIM'), '📷');
      expect(ChannelManager.getFolderDisplayEmoji('Screenshots'), '📸');
      expect(ChannelManager.getFolderDisplayEmoji('WhatsApp Images'), '💬');
      expect(ChannelManager.getFolderDisplayEmoji('WhatsApp Video'), '💬');
      expect(ChannelManager.getFolderDisplayEmoji('Download'), '⬇️');
      expect(ChannelManager.getFolderDisplayEmoji('Downloads'), '⬇️');
      expect(ChannelManager.getFolderDisplayEmoji('Instagram'), '📱');
      expect(ChannelManager.getFolderDisplayEmoji('Telegram'), '✈️');
      expect(ChannelManager.getFolderDisplayEmoji('Snapchat'), '👻');
      expect(ChannelManager.getFolderDisplayEmoji('Twitter'), '🐦');
      expect(ChannelManager.getFolderDisplayEmoji('Videos'), '🎬');
      expect(ChannelManager.getFolderDisplayEmoji('RAW'), '🎞️');
      expect(ChannelManager.getFolderDisplayEmoji('Favorites'), '⭐');
      expect(ChannelManager.getFolderDisplayEmoji('Receipts'), '📄');
      expect(ChannelManager.getFolderDisplayEmoji('CustomTrip2026'), '📁');
    });
  });
}
