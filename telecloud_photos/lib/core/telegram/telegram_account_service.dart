import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'models/telegram_account.dart';
import '../utils/telecloud_logger.dart';

class TelegramAccountService extends ChangeNotifier {
  final FlutterSecureStorage _storage;
  static const String _accountsKey = 'telecloud_saved_accounts_v1';
  static const String _activeAccountKey = 'telecloud_active_account_id';

  List<TelegramAccount> _accounts = [];
  List<TelegramAccount> get accounts => List.unmodifiable(_accounts);

  TelegramAccount? _activeAccount;
  TelegramAccount? get activeAccount => _activeAccount;

  Completer<void>? _initCompleter;

  TelegramAccountService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage() {
    init();
  }

  Future<void> init() async {
    if (_initCompleter != null) {
      return _initCompleter!.future;
    }
    _initCompleter = Completer<void>();

    try {
      final raw = await _storage.read(key: _accountsKey);
      final activeId = await _storage.read(key: _activeAccountKey);

      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> list = json.decode(raw);
        _accounts = list
            .map(
              (item) => TelegramAccount.fromMap(item as Map<String, dynamic>),
            )
            .toList();
      } else {
        _accounts = [];
      }

      if (_accounts.isNotEmpty) {
        if (activeId != null) {
          _activeAccount = _accounts.firstWhere(
            (acc) => acc.id == activeId,
            orElse: () => _accounts.first,
          );
        } else {
          _activeAccount = _accounts.firstWhere(
            (acc) => acc.isActive,
            orElse: () => _accounts.first,
          );
        }
      } else {
        _activeAccount = null;
      }

      TeleCloudLogger.auth(
        'TelegramAccountService initialized with ${_accounts.length} accounts. Active: ${_activeAccount?.displayName ?? "None"}',
      );
      notifyListeners();
    } catch (e) {
      TeleCloudLogger.auth('TelegramAccountService init error', error: e);
    } finally {
      if (!_initCompleter!.isCompleted) {
        _initCompleter!.complete();
      }
    }
  }

  Future<void> ensureInitialized() async {
    await init();
  }

  Future<void> saveAccount(
    TelegramAccount account, {
    bool makeActive = true,
  }) async {
    await ensureInitialized();
    try {
      final index = _accounts.indexWhere(
        (a) => a.id == account.id || a.telegramUserId == account.telegramUserId,
      );
      if (index >= 0) {
        _accounts[index] = account.copyWith(isActive: makeActive);
      } else {
        _accounts.add(account.copyWith(isActive: makeActive));
      }

      if (makeActive) {
        for (int i = 0; i < _accounts.length; i++) {
          if (_accounts[i].id != account.id) {
            _accounts[i] = _accounts[i].copyWith(isActive: false);
          }
        }
        _activeAccount = account.copyWith(isActive: true);
        await _storage.write(key: _activeAccountKey, value: account.id);
      }

      await _persist();
      TeleCloudLogger.auth(
        'Saved account: ${account.displayName} (active: $makeActive)',
      );
      notifyListeners();
    } catch (e) {
      TeleCloudLogger.auth('Error saving account', error: e);
    }
  }

  Future<void> setActiveAccount(String accountId) async {
    await ensureInitialized();
    try {
      final target = _accounts.firstWhere((a) => a.id == accountId);
      for (int i = 0; i < _accounts.length; i++) {
        _accounts[i] = _accounts[i].copyWith(
          isActive: _accounts[i].id == accountId,
        );
      }
      _activeAccount = target.copyWith(isActive: true);
      await _storage.write(key: _activeAccountKey, value: accountId);
      await _persist();
      TeleCloudLogger.auth(
        'Switched active account to: ${_activeAccount?.displayName}',
      );
      notifyListeners();
    } catch (e) {
      TeleCloudLogger.auth('Error setting active account $accountId', error: e);
    }
  }

  Future<void> removeAccount(String accountId) async {
    await ensureInitialized();
    try {
      final target = _accounts.firstWhere(
        (a) => a.id == accountId,
        orElse: () => _accounts.first,
      );
      _accounts.removeWhere((a) => a.id == accountId);

      // Clean up session directory if exists
      if (target.sessionDir.isNotEmpty) {
        final dir = Directory(target.sessionDir);
        if (dir.existsSync()) {
          dir.deleteSync(recursive: true);
        }
      }

      if (_activeAccount?.id == accountId) {
        if (_accounts.isNotEmpty) {
          _accounts[0] = _accounts[0].copyWith(isActive: true);
          _activeAccount = _accounts[0];
          await _storage.write(
            key: _activeAccountKey,
            value: _activeAccount!.id,
          );
        } else {
          _activeAccount = null;
          await _storage.delete(key: _activeAccountKey);
        }
      }

      await _persist();
      TeleCloudLogger.auth('Removed account: $accountId');
      notifyListeners();
    } catch (e) {
      TeleCloudLogger.auth('Error removing account $accountId', error: e);
    }
  }

  Future<String> generateSessionDirectory(String accountId) async {
    final appDir = await getApplicationDocumentsDirectory();
    final safeId = accountId.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
    final sessionPath = '${appDir.path}/tdlib_acc_$safeId';
    final dir = Directory(sessionPath);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return sessionPath;
  }

  Future<void> _persist() async {
    final raw = json.encode(_accounts.map((a) => a.toMap()).toList());
    await _storage.write(key: _accountsKey, value: raw);
  }
}
