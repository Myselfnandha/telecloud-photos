import 'dart:async';
import 'dart:io';
import 'package:tdlib/tdlib.dart';
import 'package:tdlib/td_api.dart' as td;
import '../utils/telecloud_logger.dart';

class TdlibClient {
  static final TdlibClient _instance = TdlibClient._internal();
  factory TdlibClient() => _instance;
  TdlibClient._internal();

  int _clientId = 0;
  int get clientId => _clientId;

  final _eventController = StreamController<td.TdObject>.broadcast();
  Stream<td.TdObject> get events => _eventController.stream;

  final _connectionStateController = StreamController<td.ConnectionState>.broadcast();
  Stream<td.ConnectionState> get connectionStateStream => _connectionStateController.stream;
  td.ConnectionState _currentConnectionState = const td.ConnectionStateConnecting();
  td.ConnectionState get currentConnectionState => _currentConnectionState;

  bool _isReceiving = false;
  bool _isInitialized = false;

  Future<void> initClient() async {
    if (_clientId != 0) return;
    try {
      if (!_isInitialized) {
        final libName = Platform.isAndroid ? 'libtdjson.so' : null;
        TeleCloudLogger.tdlib('Initializing native TDLib plugin ($libName)...');
        await TdPlugin.initialize(libName);
        _isInitialized = true;
        TeleCloudLogger.tdlib('Native TDLib plugin initialized successfully.');
      }
      _clientId = tdCreate();
      TeleCloudLogger.tdlib(
        'TDLib client instance created with ID: $_clientId',
      );
      if (_clientId != 0) {
        _startReceiving();
      }
    } catch (e) {
      TeleCloudLogger.tdlib('TDLib client init failed', error: e);
    }
  }

  void _startReceiving() {
    if (_isReceiving) return;
    _isReceiving = true;
    TeleCloudLogger.tdlib(
      'Started non-blocking TDLib receive loop for client $_clientId',
    );

    Future.microtask(() async {
      while (_isReceiving) {
        try {
          // Drain pending C++ events non-blockingly with 0.0s timeout to never stall Flutter UI / Choreographer
          int drainedCount = 0;
          while (drainedCount < 50) {
            final res = tdReceive(0.0);
            if (res == null) break;
            if (res is td.UpdateConnectionState) {
              _currentConnectionState = res.state;
              _connectionStateController.add(res.state);
            }
            _eventController.add(res);
            drainedCount++;
          }
        } catch (e) {
          TeleCloudLogger.tdlib('TDLib receive loop error', error: e);
        }
        // Yield to the Flutter frame rendering pipeline (120Hz/60Hz)
        await Future.delayed(const Duration(milliseconds: 20));
      }
    });
  }

  void send(td.TdFunction event, [dynamic extra]) {
    TeleCloudLogger.tdlib('Sending TDLib request: ${event.runtimeType}');
    if (_clientId == 0) {
      initClient().then((_) {
        if (_clientId != 0) {
          try {
            tdSend(_clientId, event, extra);
          } catch (e) {
            TeleCloudLogger.tdlib(
              'Failed to send TDLib event after lazy init',
              error: e,
            );
          }
        }
      });
      return;
    }

    try {
      tdSend(_clientId, event, extra);
    } catch (e) {
      TeleCloudLogger.tdlib('Failed to send TDLib event', error: e);
    }
  }

  td.TdObject? execute(td.TdFunction event) {
    try {
      TeleCloudLogger.tdlib(
        'Executing synchronous TDLib function: ${event.runtimeType}',
      );
      return tdExecute(event);
    } catch (e) {
      TeleCloudLogger.tdlib('TDLib execute error', error: e);
      return null;
    }
  }

  void enableMtprotoProxy({
    required String server,
    required int port,
    required String secret,
  }) {
    TeleCloudLogger.tdlib('Configuring MTProto Proxy ($server:$port)...');
    send(
      td.AddProxy(
        server: server,
        port: port,
        enable: true,
        type: td.ProxyTypeMtproto(secret: secret),
      ),
    );
  }

  void disableProxy() {
    TeleCloudLogger.tdlib('Disabling active Telegram proxy...');
    send(const td.DisableProxy());
  }

  void stopClient() {
    TeleCloudLogger.tdlib('Stopping TDLib client $_clientId');
    _isReceiving = false;
    _clientId = 0;
  }

  Future<void> restartClient() async {
    if (_clientId != 0) {
      try {
        tdSend(_clientId, const td.Close());
      } catch (_) {}
    }
    stopClient();
    await Future.delayed(const Duration(milliseconds: 200));
    await initClient();
  }

  Future<void> clearSessionFiles(String sessionPath) async {
    stopClient();
    try {
      final dir = Directory(sessionPath);
      if (dir.existsSync()) {
        dir.deleteSync(recursive: true);
      }
      final filesDir = Directory('${sessionPath}_files');
      if (filesDir.existsSync()) {
        filesDir.deleteSync(recursive: true);
      }
      TeleCloudLogger.tdlib('Cleared TDLib session files at $sessionPath');
    } catch (e) {
      TeleCloudLogger.tdlib('Error clearing session files', error: e);
    }
    await initClient();
  }

  void dispose() {
    stopClient();
    _eventController.close();
    _connectionStateController.close();
  }
}
