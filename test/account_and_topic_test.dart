import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:telecloud_photos/core/constants/app_constants.dart';
import 'package:telecloud_photos/core/telegram/models/telegram_account.dart';
import 'package:telecloud_photos/core/telegram/telegram_account_service.dart';

// In-Memory mock for FlutterSecureStorage to test persistence
class MockSecureStorage extends Fake implements FlutterSecureStorage {
  final Map<String, String> _data = {};

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return _data[key];
  }

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value == null) {
      _data.remove(key);
    } else {
      _data[key] = value;
    }
  }

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _data.remove(key);
  }

  @override
  Future<Map<String, String>> readAll({
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return Map.from(_data);
  }

  @override
  Future<void> deleteAll({
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _data.clear();
  }

  @override
  Future<bool> containsKey({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return _data.containsKey(key);
  }
}

void main() {
  group('TelegramAccount Model Tests', () {
    test('1. Serialization and deserialization preserves all fields', () {
      final now = DateTime(2026, 8, 17, 12, 0, 0);
      final account = TelegramAccount(
        id: '12345678',
        telegramUserId: 12345678,
        phoneNumber: '+1234567890',
        firstName: 'Alex',
        lastName: 'Morgan',
        username: 'alex_photo',
        profilePhotoPath: '/cache/photo.jpg',
        backupChannelId: -100123456789,
        sessionDir: '/data/user/0/com.telecloud/tdlib_acc_12345678',
        isActive: true,
        createdAt: now,
      );

      final jsonString = account.toJson();
      final decoded = TelegramAccount.fromJson(jsonString);

      expect(decoded.id, '12345678');
      expect(decoded.telegramUserId, 12345678);
      expect(decoded.phoneNumber, '+1234567890');
      expect(decoded.firstName, 'Alex');
      expect(decoded.lastName, 'Morgan');
      expect(decoded.displayName, 'Alex Morgan');
      expect(decoded.username, 'alex_photo');
      expect(decoded.backupChannelId, -100123456789);
      expect(decoded.isActive, true);
    });

    test('2. DisplayName formats correctly without lastName', () {
      final account = TelegramAccount(
        id: '999',
        telegramUserId: 999,
        phoneNumber: '+987654321',
        firstName: 'Jessica',
        sessionDir: '/data/user/0/com.telecloud/tdlib_acc_999',
        createdAt: DateTime.now(),
      );

      expect(account.displayName, 'Jessica');
    });
  });

  group('TelegramAccountService Multi-Account Tests', () {
    late MockSecureStorage mockStorage;
    late TelegramAccountService accountService;

    setUp(() {
      mockStorage = MockSecureStorage();
      accountService = TelegramAccountService(storage: mockStorage);
    });

    test('1. Saving new account sets it active and persists', () async {
      final acc1 = TelegramAccount(
        id: 'user_1',
        telegramUserId: 101,
        phoneNumber: '+111111111',
        firstName: 'Account One',
        sessionDir: '/dir/acc1',
        isActive: true,
        createdAt: DateTime.now(),
      );

      await accountService.saveAccount(acc1, makeActive: true);

      expect(accountService.accounts.length, 1);
      expect(accountService.activeAccount?.id, 'user_1');
      expect(accountService.activeAccount?.firstName, 'Account One');
    });

    test('2. Adding second account allows fast switching', () async {
      final acc1 = TelegramAccount(
        id: 'user_1',
        telegramUserId: 101,
        phoneNumber: '+111111111',
        firstName: 'Account One',
        sessionDir: '/dir/acc1',
        isActive: true,
        createdAt: DateTime.now(),
      );

      final acc2 = TelegramAccount(
        id: 'user_2',
        telegramUserId: 102,
        phoneNumber: '+222222222',
        firstName: 'Account Two',
        sessionDir: '/dir/acc2',
        isActive: false,
        createdAt: DateTime.now(),
      );

      await accountService.saveAccount(acc1, makeActive: true);
      await accountService.saveAccount(acc2, makeActive: false);

      expect(accountService.accounts.length, 2);
      expect(accountService.activeAccount?.id, 'user_1');

      // Switch to account 2
      await accountService.setActiveAccount('user_2');

      expect(accountService.activeAccount?.id, 'user_2');
      expect(accountService.activeAccount?.phoneNumber, '+222222222');
      expect(
        accountService.accounts.firstWhere((a) => a.id == 'user_1').isActive,
        false,
      );
      expect(
        accountService.accounts.firstWhere((a) => a.id == 'user_2').isActive,
        true,
      );
    });

    test(
      '3. Removing active account automatically promotes remaining account',
      () async {
        final acc1 = TelegramAccount(
          id: 'user_1',
          telegramUserId: 101,
          phoneNumber: '+111111111',
          firstName: 'Account One',
          sessionDir: '',
          isActive: true,
          createdAt: DateTime.now(),
        );

        final acc2 = TelegramAccount(
          id: 'user_2',
          telegramUserId: 102,
          phoneNumber: '+222222222',
          firstName: 'Account Two',
          sessionDir: '',
          isActive: false,
          createdAt: DateTime.now(),
        );

        await accountService.saveAccount(acc1, makeActive: true);
        await accountService.saveAccount(acc2, makeActive: false);

        // Remove active account 1
        await accountService.removeAccount('user_1');

        expect(accountService.accounts.length, 1);
        expect(accountService.activeAccount?.id, 'user_2');
        expect(accountService.activeAccount?.isActive, true);
      },
    );
  });

  group('ChannelManager Supergroup Discovery Tests', () {
    test('1. AppConstants defines consistent supergroup title', () {
      expect(AppConstants.telegramChannelTitle, 'TeleCloud Photos 📸');
      expect(AppConstants.channelIdKey, 'telecloud_channel_id');
    });
  });
}
