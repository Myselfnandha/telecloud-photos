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

  // Passive scanner + phone interceptor + auto-create app + auto-extract credentials
  static const String _jsAutoToolsAndScanScript = '''
    (function() {
      var hasClickedApps = false;

      function checkAndScan() {
        try {
          var currentUrl = window.location.href;

          // 1. Intercept user's phone number as they type or submit on auth page
          var phoneEl = document.querySelector('input[name="phone"], #my_login_phone, input[type="tel"]');
          if (phoneEl && phoneEl.value && phoneEl.value.trim().length >= 8) {
            window.__telecloud_phone = phoneEl.value.trim();
          }

          // 2. When code is entered & user reaches portal menu, auto-click "API development tools"
          if (!currentUrl.includes('/apps') && !currentUrl.includes('/auth')) {
            if (!hasClickedApps) {
              var links = document.querySelectorAll('a');
              for (var i = 0; i < links.length; i++) {
                var href = links[i].getAttribute('href') || '';
                var text = (links[i].innerText || '').toLowerCase();
                if (href === '/apps' || href.indexOf('/apps') !== -1 || text.indexOf('api development tools') !== -1) {
                  hasClickedApps = true;
                  links[i].click();
                  return;
                }
              }
            }
          }

          // 3. Auto-fill and submit "Create new application" form if displayed
          if (currentUrl.includes('/apps')) {
            var appTitle = document.querySelector('input[name="app_title"], #app_title');
            var appShort = document.querySelector('input[name="app_shortname"], #app_shortname');
            if (appTitle && (!appTitle.value || appTitle.value === '')) {
              appTitle.value = 'TeleCloud Photos';
              if (appShort) {
                appShort.value = 'telecloud' + Math.floor(Math.random() * 10000);
              }
              var appDesc = document.querySelector('textarea[name="app_desc"], #app_desc');
              if (appDesc) appDesc.value = 'TeleCloud Private Photo Cloud';
              var platformRadio = document.querySelector('input[value="android"], input[value="other"]');
              if (platformRadio) platformRadio.checked = true;
              var submitBtn = document.querySelector('button[type="submit"], input[type="submit"]');
              if (submitBtn) {
                submitBtn.click();
                return;
              }
            }
          }

          // 4. Scan page contents for api_id and api_hash
          var bodyText = document.body ? document.body.innerText : '';
          
          var idMatch = bodyText.match(/(?:api[-_]?id|App api_id)\\s*[:=]?\\s*(\\d{5,10})/i);
          var hashMatch = bodyText.match(/(?:api[-_]?hash|App api_hash)\\s*[:=]?\\s*([a-fA-F0-9]{32})/i);

          if (!idMatch || !hashMatch) {
            var allInputs = document.querySelectorAll('input, span, td, div, p, strong, b');
            var rawAll = '';
            for (var j = 0; j < allInputs.length; j++) {
              rawAll += ' ' + (allInputs[j].innerText || allInputs[j].value || '');
            }
            if (!idMatch) idMatch = rawAll.match(/(?:api[-_]?id|App api_id)\\s*[:=]?\\s*(\\d{5,10})/i);
            if (!hashMatch) hashMatch = rawAll.match(/([a-fA-F0-9]{32})/i);
          }

          if (idMatch && hashMatch) {
            if (window.TeleCloudAuthChannel) {
              window.TeleCloudAuthChannel.postMessage(JSON.stringify({
                api_id: idMatch[1],
                api_hash: hashMatch[1],
                phone_number: window.__telecloud_phone || ''
              }));
              return true;
            }
          }
        } catch (e) {
          console.error("Auto tools & scan error", e);
        }
        return false;
      }

      if (!window.__telecloudAutoScanner) {
        window.__telecloudAutoScanner = setInterval(checkAndScan, 800);
      }
      checkAndScan();
    })();
  ''';

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(
        'Mozilla/5.0 (Linux; Android 15; Pixel 8 Pro) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Mobile Safari/537.36',
      )
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
            // Inject script to auto-click API development tools & scan credentials
            _controller.runJavaScript(_jsAutoToolsAndScanScript);
          },
          onWebResourceError: (WebResourceError error) {
            TeleCloudLogger.auth(
                'WebView resource error: ${error.description}');
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
      final phone = data['phone_number']?.toString();

      if (apiId != null && apiHash != null && apiHash.length >= 30) {
        setState(() {
          _isSuccess = true;
          _statusMessage = 'Credentials extracted! Connecting...';
        });

        TeleCloudLogger.auth(
            'Successfully auto-extracted Telegram API ID: $apiId, Phone: $phone');

        // Auto-close quickly so user transitions smoothly
        Future.delayed(const Duration(milliseconds: 350), () {
          if (mounted) {
            Navigator.of(context).pop(
              ParsedCredentials(
                apiId: apiId,
                apiHash: apiHash,
                phoneNumber: phone != null && phone.trim().isNotEmpty ? phone.trim() : null,
              ),
            );
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
                  child: const Icon(Icons.auto_awesome_rounded,
                      color: Color(0xFF007AFF), size: 20),
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
                          color: _isSuccess
                              ? const Color(0xFF30D158)
                              : Colors.white60,
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
                  icon: const Icon(Icons.apps_rounded,
                      color: Color(0xFF38BDF8), size: 16),
                  label: const Text('API Tools',
                      style: TextStyle(color: Color(0xFF38BDF8), fontSize: 12)),
                  onPressed: () {
                    _controller
                        .loadRequest(Uri.parse('https://my.telegram.org/apps'));
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
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFF007AFF)),
              minHeight: 2,
            )
          else
            const Divider(color: Colors.white12, height: 1),

          // WebView & Success Overlay
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
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
                              color: const Color(0xFF30D158)
                                  .withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check_circle_rounded,
                                color: Color(0xFF30D158), size: 54),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Credentials Extracted!',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Auto-closing and saving credentials...',
                            style:
                                TextStyle(color: Colors.white60, fontSize: 14),
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
