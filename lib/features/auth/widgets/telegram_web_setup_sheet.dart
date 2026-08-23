import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../core/utils/telecloud_logger.dart';
import '../../../core/utils/telegram_credential_parser.dart';

class TelegramWebSetupSheet extends StatefulWidget {
  const TelegramWebSetupSheet({super.key});

  static Future<ParsedCredentials?> show(BuildContext context) {
    return showModalBottomSheet<ParsedCredentials>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const TelegramWebSetupSheet(),
    );
  }

  @override
  State<TelegramWebSetupSheet> createState() => _TelegramWebSetupSheetState();
}

class _TelegramWebSetupSheetState extends State<TelegramWebSetupSheet> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _isSuccess = false;
  String _statusMessage = 'Connecting to my.telegram.org...';

  static const String _jsExtractionScript = '''
    (function() {
      function scanForCredentials() {
        try {
          var bodyText = document.body ? document.body.innerText : '';
          
          // Pattern matching for API ID & Hash
          var idMatch = bodyText.match(/(?:api[-_]?id|App api_id)\\s*[:=]?\\s*(\\d{5,10})/i);
          var hashMatch = bodyText.match(/(?:api[-_]?hash|App api_hash)\\s*[:=]?\\s*([a-fA-F0-9]{32})/i);

          if (idMatch && hashMatch) {
            if (window.TeleCloudAuthChannel) {
              window.TeleCloudAuthChannel.postMessage(JSON.stringify({
                api_id: idMatch[1],
                api_hash: hashMatch[1]
              }));
              return true;
            }
          }

          // If on /apps creation form page and no app created yet, auto-fill
          var titleInput = document.querySelector('input[name="app_title"], #app_title');
          var shortNameInput = document.querySelector('input[name="app_short_name"], #app_short_name');
          var platformRadio = document.querySelector('input[value="android"], #app_platform_android');
          var submitBtn = document.querySelector('button[type="submit"], input[type="submit"]');

          if (titleInput && shortNameInput && titleInput.value === '') {
            titleInput.value = 'TeleCloud Photos';
            shortNameInput.value = 'telecloudphotos';
            if (platformRadio) platformRadio.checked = true;
            if (submitBtn) {
              submitBtn.click();
            }
          }
        } catch (e) {
          console.error("Auto extraction error", e);
        }
        return false;
      }

      if (!window.__telecloudScanner) {
        window.__telecloudScanner = setInterval(scanForCredentials, 1200);
        scanForCredentials();
      }
    })();
  ''';

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0F172A))
      ..addJavaScriptChannel(
        'TeleCloudAuthChannel',
        onMessageReceived: (JavaScriptMessage message) {
          _handleExtractedCredentials(message.message);
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
              if (url.contains('/apps')) {
                _statusMessage = 'Detecting API Credentials...';
              } else if (url.contains('/auth')) {
                _statusMessage = 'Log in with your Telegram code';
              }
            });
          },
          onPageFinished: (String url) {
            setState(() => _isLoading = false);
            _controller.runJavaScript(_jsExtractionScript);

            // If logged in and on index page, auto-redirect to /apps
            if (!url.contains('/apps') && !url.contains('/auth/login') && !url.contains('/auth/send_password')) {
              _controller.runJavaScript('''
                if (window.location.pathname !== '/apps') {
                  window.location.href = 'https://my.telegram.org/apps';
                }
              ''');
            }
          },
          onWebResourceError: (WebResourceError error) {
            TeleCloudLogger.auth('WebView resource error: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse('https://my.telegram.org/auth'));
  }

  void _handleExtractedCredentials(String payload) {
    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      final apiId = int.tryParse(data['api_id']?.toString() ?? '');
      final apiHash = data['api_hash']?.toString();

      if (apiId != null && apiHash != null && apiHash.length >= 30) {
        setState(() {
          _isSuccess = true;
          _statusMessage = 'Credentials extracted! Auto-closing...';
        });

        TeleCloudLogger.auth('Successfully auto-extracted Telegram API ID: $apiId');

        // Auto-close after 800ms success animation
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) {
            Navigator.of(context).pop(ParsedCredentials(apiId: apiId, apiHash: apiHash));
          }
        });
      }
    } catch (e) {
      TeleCloudLogger.auth('Error decoding extracted credentials: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: const BoxDecoration(
        color: Color(0xFF0B111E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),
          const SizedBox(height: 12),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF007AFF).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF007AFF), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Automated Telegram Setup',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _statusMessage,
                        style: TextStyle(
                          color: _isSuccess ? const Color(0xFF30D158) : Colors.white60,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 20),

          // Helper Tip Banner
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: const Row(
              children: [
                Icon(Icons.lightbulb_rounded, color: Color(0xFFFF9F0A), size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Log in with your Telegram code. The app will auto-create & copy credentials, then auto-close this window.',
                    style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.3),
                  ),
                ),
              ],
            ),
          ),

          // WebView & Loader
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: WebViewWidget(controller: _controller),
                ),
                if (_isLoading)
                  Container(
                    color: const Color(0xFF0B111E).withValues(alpha: 0.7),
                    child: const Center(
                      child: CircularProgressIndicator(color: Color(0xFF007AFF)),
                    ),
                  ),
                if (_isSuccess)
                  Container(
                    color: const Color(0xFF0B111E).withValues(alpha: 0.92),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF30D158).withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check_circle_rounded, color: Color(0xFF30D158), size: 54),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Credentials Configured!',
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Auto-closing browser window...',
                            style: TextStyle(color: Colors.white60, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
