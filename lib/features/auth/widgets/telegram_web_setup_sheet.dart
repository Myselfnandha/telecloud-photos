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
  int _loadingProgress = 0;
  bool _isSuccess = false;
  String _statusMessage = 'Log in with your Telegram code';

  // Pure passive credential scanner: NEVER clicks buttons, NEVER reloads page.
  static const String _jsPassiveScanScript = '''
    (function() {
      function scanOnly() {
        try {
          var bodyText = document.body ? document.body.innerText : '';
          
          // Pattern matching for API ID & Hash in page text
          var idMatch = bodyText.match(/(?:api[-_]?id|App api_id)\\s*[:=]?\\s*(\\d{5,10})/i);
          var hashMatch = bodyText.match(/(?:api[-_]?hash|App api_hash)\\s*[:=]?\\s*([a-fA-F0-9]{32})/i);

          // Also check form input values / uneditable spans if present
          if (!idMatch || !hashMatch) {
            var allInputs = document.querySelectorAll('input, span, td, div');
            var rawAll = '';
            for (var i = 0; i < allInputs.length; i++) {
              rawAll += ' ' + (allInputs[i].innerText || allInputs[i].value || '');
            }
            if (!idMatch) idMatch = rawAll.match(/(?:api[-_]?id|App api_id)\\s*[:=]?\\s*(\\d{5,10})/i);
            if (!hashMatch) hashMatch = rawAll.match(/([a-fA-F0-9]{32})/i);
          }

          if (idMatch && hashMatch) {
            if (window.TeleCloudAuthChannel) {
              window.TeleCloudAuthChannel.postMessage(JSON.stringify({
                api_id: idMatch[1],
                api_hash: hashMatch[1]
              }));
              return true;
            }
          }
        } catch (e) {
          console.error("Passive scan error", e);
        }
        return false;
      }

      if (!window.__telecloudPassiveScanner) {
        window.__telecloudPassiveScanner = setInterval(scanOnly, 1000);
      }
      scanOnly();
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
          onProgress: (progress) {
            if (mounted) setState(() => _loadingProgress = progress);
          },
          onPageStarted: (String url) {
            if (mounted) {
              setState(() {
                if (url.contains('/apps')) {
                  _statusMessage = 'Scanning for API ID & Hash...';
                } else if (url.contains('/auth')) {
                  _statusMessage = 'Log in with your Telegram code';
                } else {
                  _statusMessage = 'my.telegram.org';
                }
              });
            }
          },
          onPageFinished: (String url) {
            if (mounted) {
              setState(() => _loadingProgress = 100);
            }
            // Inject passive scanner script ONLY (no page reloads or redirects)
            _controller.runJavaScript(_jsPassiveScanScript);
          },
          onWebResourceError: (WebResourceError error) {
            TeleCloudLogger.auth('WebView resource error: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse('https://my.telegram.org/auth'));
  }

  void _handleExtractedCredentials(String payload) {
    if (_isSuccess) return;
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

        // Auto-close after 600ms success animation
        Future.delayed(const Duration(milliseconds: 600), () {
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
      height: MediaQuery.of(context).size.height * 0.92,
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
                        'Telegram Web Assistant',
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
                // Direct shortcut to /apps if user is logged in
                TextButton.icon(
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  icon: const Icon(Icons.apps_rounded, color: Color(0xFF38BDF8), size: 16),
                  label: const Text('API Tools', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 12)),
                  onPressed: () {
                    _controller.loadRequest(Uri.parse('https://my.telegram.org/apps'));
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Non-intrusive loading bar
          if (_loadingProgress < 100)
            LinearProgressIndicator(
              value: _loadingProgress / 100.0,
              backgroundColor: Colors.transparent,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF007AFF)),
              minHeight: 2,
            )
          else
            const Divider(color: Colors.white12, height: 1),

          // WebView & Success Overlay
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: WebViewWidget(controller: _controller),
                ),
                if (_isSuccess)
                  Container(
                    color: const Color(0xFF0B111E).withValues(alpha: 0.95),
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
                            'Credentials Extracted!',
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Auto-closing and saving credentials...',
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
