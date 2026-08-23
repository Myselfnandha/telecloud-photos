import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tdlib/td_api.dart' as td;
import '../constants/app_constants.dart';
import '../utils/telecloud_logger.dart';
import 'models/telegram_account.dart';
import 'telegram_account_service.dart';
import 'tdlib_client.dart';
import 'channel_manager.dart';

enum AuthState {
  uninitialized,
  waitingForPhoneNumber,
  waitingForCode,
  waitingForPassword,
  authenticated,
  error,
}

class TelegramAuthManager extends ChangeNotifier {
  final TdlibClient _client;
  final TelegramAccountService? _accountService;
  final ChannelManager? _channelManager;
  StreamSubscription? _sub;
  bool _isDisposed = false;

  AuthState _state = AuthState.uninitialized;
  AuthState get state => _state;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  int? _targetChannelId;
  int? get targetChannelId => _targetChannelId;

  bool _parametersSent = false;
  final String? _currentSessionDir;

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  TelegramAuthManager({
    TdlibClient? client,
    TelegramAccountService? accountService,
    ChannelManager? channelManager,
    String? sessionDir,
  }) : _client = client ?? TdlibClient(),
       _accountService = accountService,
       _channelManager = channelManager,
       _currentSessionDir = sessionDir {
    _init();
  }

  void _init() async {
    TeleCloudLogger.auth('Initializing TelegramAuthManager...');
    _sub = _client.events.listen(_handleUpdate);
    await initClient();
  }

  Future<void> initClient() async {
    await _client.initClient();
    _client.send(const td.GetAuthorizationState());
  }

  void _handleUpdate(td.TdObject event) async {
    if (event is td.UpdateAuthorizationState) {
      final authState = event.authorizationState;
      TeleCloudLogger.auth(
        'UpdateAuthorizationState received: ${authState.runtimeType}',
      );
      await _processAuthState(authState);
    } else if (event is td.AuthorizationState) {
      TeleCloudLogger.auth(
        'Direct AuthorizationState received: ${event.runtimeType}',
      );
      await _processAuthState(event);
    } else if (event is td.TdError) {
      TeleCloudLogger.auth(
        'TDLib Auth Error: [${event.code}] ${event.message}',
      );
      // Ignore benign parameter errors and internal file lock races
      final msgLower = event.message.toLowerCase();
      if (msgLower.contains('settdlibparameters') ||
          msgLower.contains('settodlibparameters') ||
          msgLower.contains('unexpected settdlibparameters') ||
          msgLower.contains('td.binlog') ||
          msgLower.contains('already in use')) {
        return;
      }
      _errorMessage = event.message;
      if (_state == AuthState.waitingForCode &&
          (event.code == 400 ||
              msgLower.contains('phone') ||
              msgLower.contains('api'))) {
        _state = AuthState.waitingForPhoneNumber;
      }
      notifyListeners();
    }
  }

  Future<void> _processAuthState(td.AuthorizationState authState) async {
    if (authState is td.AuthorizationStateWaitTdlibParameters) {
      await _sendTdlibParameters();
    } else if (authState is td.AuthorizationStateWaitPhoneNumber) {
      TeleCloudLogger.auth('Auth State -> waitingForPhoneNumber');
      _state = AuthState.waitingForPhoneNumber;
      _errorMessage = null;
      notifyListeners();
    } else if (authState is td.AuthorizationStateWaitCode) {
      TeleCloudLogger.auth('Auth State -> waitingForCode');
      _state = AuthState.waitingForCode;
      _errorMessage = null;
      notifyListeners();
    } else if (authState is td.AuthorizationStateWaitPassword) {
      TeleCloudLogger.auth('Auth State -> waitingForPassword (2FA enabled)');
      _state = AuthState.waitingForPassword;
      _errorMessage = null;
      notifyListeners();
    } else if (authState is td.AuthorizationStateReady) {
      TeleCloudLogger.auth(
        'Auth State -> authenticated! Ensuring backup channel & profile...',
      );
      _state = AuthState.authenticated;
      _errorMessage = null;
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('telecloud_is_authenticated', true);
      } catch (_) {}
      await _ensureDedicatedChannel();
      await _fetchAndPersistAccount();
      notifyListeners();
    } else if (authState is td.AuthorizationStateClosed) {
      TeleCloudLogger.auth('Auth State -> closed / uninitialized');
      _state = AuthState.uninitialized;
      _parametersSent = false;
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('telecloud_is_authenticated', false);
      } catch (_) {}
      notifyListeners();
    }
  }

  Future<void> _fetchAndPersistAccount() async {
    if (_accountService == null) return;
    try {
      final completer = Completer<td.User?>();
      late StreamSubscription userSub;
      userSub = _client.events.listen((event) {
        if (event is td.User) {
          completer.complete(event);
          userSub.cancel();
        } else if (event is td.TdError) {
          completer.complete(null);
          userSub.cancel();
        }
      });
      _client.send(const td.GetMe());
      final user = await completer.future.timeout(
        const Duration(seconds: 4),
        onTimeout: () {
          userSub.cancel();
          return null;
        },
      );

      if (user != null) {
        final account = TelegramAccount(
          id: user.id.toString(),
          telegramUserId: user.id,
          phoneNumber: user.phoneNumber,
          firstName: user.firstName,
          lastName: user.lastName.isNotEmpty ? user.lastName : null,
          username: user.usernames?.activeUsernames.isNotEmpty == true
              ? user.usernames!.activeUsernames.first
              : null,
          profilePhotoPath: user.profilePhoto?.small.local.path,
          backupChannelId: _targetChannelId,
          sessionDir: _currentSessionDir ?? '',
          isActive: true,
          createdAt: DateTime.now(),
        );
        await _accountService.saveAccount(account, makeActive: true);
      }
    } catch (e) {
      TeleCloudLogger.auth(
        'Error fetching and persisting account profile',
        error: e,
      );
    }
  }

  Future<void> _sendTdlibParameters() async {
    if (_parametersSent) {
      TeleCloudLogger.auth(
        'TDLib parameters already sent, skipping redundant SetTdlibParameters.',
      );
      return;
    }
    final dir = await getApplicationDocumentsDirectory();
    final dbDir = Directory(_currentSessionDir ?? '${dir.path}/tdlib');
    final filesDir = Directory('${dbDir.path}_files');
    if (!dbDir.existsSync()) dbDir.createSync(recursive: true);
    if (!filesDir.existsSync()) filesDir.createSync(recursive: true);

    TeleCloudLogger.auth(
      'Setting TDLib Parameters (apiId=${AppConstants.telegramApiId}, dbPath=${dbDir.path})...',
    );
    _parametersSent = true;
    _client.send(
      td.SetTdlibParameters(
        useTestDc: false,
        databaseDirectory: dbDir.path,
        filesDirectory: filesDir.path,
        databaseEncryptionKey: '',
        useFileDatabase: true,
        useChatInfoDatabase: true,
        useMessageDatabase: true,
        useSecretChats: false,
        apiId: AppConstants.telegramApiId,
        apiHash: AppConstants.telegramApiHash,
        systemLanguageCode: 'en',
        deviceModel: 'Android Mobile',
        systemVersion: 'Android 14',
        applicationVersion: '1.0.0',
        enableStorageOptimizer: true,
        ignoreFileNames: false,
      ),
    );
  }

  /// Ensures a dedicated private channel exists for TeleCloud Photos
  Future<void> _ensureDedicatedChannel() async {
    final prefs = await SharedPreferences.getInstance();
    final savedChannelId = prefs.getInt(AppConstants.channelIdKey);

    if (savedChannelId != null) {
      _targetChannelId = savedChannelId;
      TeleCloudLogger.auth(
        'Found existing dedicated backup channel: $_targetChannelId',
      );
      return;
    }

    if (_channelManager != null) {
      final channelId = await _channelManager.ensureBackupChannel();
      if (channelId != null) {
        _targetChannelId = channelId;
        await prefs.setInt(AppConstants.channelIdKey, channelId);
        TeleCloudLogger.auth(
          'Delegated dedicated backup channel resolved: $channelId',
        );
        return;
      }
    }

    // Fallback ChannelManager search & discovery before creation
    final mgr = ChannelManager(client: _client);
    final channelId = await mgr.ensureBackupChannel();
    if (channelId != null) {
      _targetChannelId = channelId;
      await prefs.setInt(AppConstants.channelIdKey, channelId);
      TeleCloudLogger.auth(
        'Fallback dedicated backup channel resolved: $channelId',
      );
    }
  }

  Future<void> restartClient() async {
    TeleCloudLogger.auth('Restarting TDLib client with fresh parameters...');
    _parametersSent = false;
    _errorMessage = null;
    _state = AuthState.uninitialized;
    notifyListeners();
    await _client.restartClient();
    _client.send(const td.GetAuthorizationState());
  }

  Future<void> sendPhoneNumber(String phoneNumber) async {
    _errorMessage = null;
    String formatted = phoneNumber.trim();
    if (!formatted.startsWith('+')) {
      formatted = '+$formatted';
    }

    TeleCloudLogger.auth(
      'Submitting phone number: $formatted to Telegram TDLib...',
    );

    await _client.initClient();

    _client.send(
      td.SetAuthenticationPhoneNumber(
        phoneNumber: formatted,
        settings: const td.PhoneNumberAuthenticationSettings(
          allowFlashCall: false,
          allowMissedCall: false,
          isCurrentPhoneNumber: false,
          allowSmsRetrieverApi: false,
          authenticationTokens: [],
        ),
      ),
    );
  }

  void sendCode(String code) {
    TeleCloudLogger.auth('Submitting verification OTP code to TDLib: $code');
    _errorMessage = null;
    _client.send(td.CheckAuthenticationCode(code: code.trim()));
  }

  void sendPassword(String password) {
    TeleCloudLogger.auth('Submitting 2FA cloud password to TDLib...');
    _errorMessage = null;
    _client.send(td.CheckAuthenticationPassword(password: password));
  }

  void logout() {
    TeleCloudLogger.auth('Logging out from Telegram Cloud...');
    _client.send(const td.LogOut());
  }

  @override
  void dispose() {
    _isDisposed = true;
    _sub?.cancel();
    super.dispose();
  }
}
