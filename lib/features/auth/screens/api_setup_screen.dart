import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/di/providers.dart';
import '../../../core/utils/telegram_credential_parser.dart';
import '../widgets/telegram_web_setup_sheet.dart';

class ApiSetupScreen extends ConsumerStatefulWidget {
  const ApiSetupScreen({super.key});

  @override
  ConsumerState<ApiSetupScreen> createState() => _ApiSetupScreenState();
}

class _ApiSetupScreenState extends ConsumerState<ApiSetupScreen> with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  final _apiIdController = TextEditingController();
  final _apiHashController = TextEditingController();

  bool _obscureHash = true;
  bool _isTestingCredentials = false;
  String? _statusText;
  String? _errorMessage;
  ParsedCredentials? _detectedClipboardCredentials;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Manual credentials are kept empty by default as requested
    _apiIdController.text = '';
    _apiHashController.text = '';

    _checkClipboardForCredentials();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkClipboardForCredentials();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _apiIdController.dispose();
    _apiHashController.dispose();
    super.dispose();
  }

  Future<void> _checkClipboardForCredentials() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      if (data?.text != null && data!.text!.trim().isNotEmpty) {
        final parsed = TelegramCredentialParser.parse(data.text!);
        if (parsed.isValid && mounted) {
          setState(() {
            _detectedClipboardCredentials = parsed;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _launchWebAssistant() async {
    final credentials = await TelegramWebSetupSheet.show(context);
    if (credentials != null && credentials.isValid && mounted) {
      _apiIdController.text = credentials.apiId.toString();
      _apiHashController.text = credentials.apiHash!;
      await _validateAndProceed(credentials.apiId!, credentials.apiHash!);
    }
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text == null || data!.text!.trim().isEmpty) {
      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        messenger.clearSnackBars();
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Clipboard is empty'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    final parsed = TelegramCredentialParser.parse(data.text!);
    if (parsed.apiId != null) {
      _apiIdController.text = parsed.apiId.toString();
    }
    if (parsed.apiHash != null) {
      _apiHashController.text = parsed.apiHash!;
    }

    if (parsed.isValid && mounted) {
      final messenger = ScaffoldMessenger.of(context);
      messenger.clearSnackBars();
      messenger.showSnackBar(
        SnackBar(
          content: Text('Pasted API ID: ${parsed.apiId} & Hash!'),
          backgroundColor: const Color(0xFF30D158),
          duration: const Duration(seconds: 2),
        ),
      );
    } else if (mounted) {
      final messenger = ScaffoldMessenger.of(context);
      messenger.clearSnackBars();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Could not detect full Telegram API credentials in clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _validateAndProceed(int apiId, String apiHash) async {
    setState(() {
      _isTestingCredentials = true;
      _errorMessage = null;
      _statusText = 'Applying credentials to Telegram engine...';
    });

    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    try {
      // 1. Reconfigure active TDLib engine with custom credentials
      final authManager = ref.read(telegramAuthManagerProvider);
      await authManager.configureCredentials(apiId: apiId, apiHash: apiHash);

      if (!mounted) return;

      setState(() {
        _isTestingCredentials = false;
        _statusText = null;
      });

      messenger.showSnackBar(
        const SnackBar(
          content: Text('✓ API credentials configured! Proceeding to phone verification...'),
          backgroundColor: Color(0xFF30D158),
          duration: Duration(seconds: 2),
        ),
      );

      // 2. Direct transition to Step 2 (Phone Login)
      router.go('/login');
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTestingCredentials = false;
          _errorMessage = 'Error configuring credentials: $e';
          _statusText = null;
        });
      }
    }
  }

  Future<void> _onManualSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    final apiId = int.parse(_apiIdController.text.trim());
    final apiHash = _apiHashController.text.trim();
    await _validateAndProceed(apiId, apiHash);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: const Color(0xFF000000),
        elevation: 0,
        title: const Text(
          'Step 1 of 3 · API Setup',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Step Progress Indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A84FF).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF0A84FF).withValues(alpha: 0.4)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.vpn_key_rounded, color: Color(0xFF0A84FF), size: 14),
                      SizedBox(width: 6),
                      Text(
                        'STEP 1 OF 3 · API CREDENTIALS',
                        style: TextStyle(
                          color: Color(0xFF0A84FF),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Title
                const Text(
                  'Telegram API Setup',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Set up your Telegram App credentials to enable unlimited cloud backup.',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                ),
                const SizedBox(height: 20),

                // Error message banner if test failed
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF453A).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFF453A)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Color(0xFFFF453A), size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Color(0xFFFF453A), fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Proactive Detected Banner
                if (_detectedClipboardCredentials != null) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0A84FF), Color(0xFF0051A8)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0A84FF).withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.auto_awesome, color: Colors.white, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Credentials Detected in Clipboard!',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'App ID: ${_detectedClipboardCredentials!.apiId}',
                                style: const TextStyle(color: Colors.white70, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF0051A8),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () {
                            _apiIdController.text = _detectedClipboardCredentials!.apiId.toString();
                            _apiHashController.text = _detectedClipboardCredentials!.apiHash!;
                            _validateAndProceed(
                              _detectedClipboardCredentials!.apiId!,
                              _detectedClipboardCredentials!.apiHash!,
                            );
                          },
                          child: const Text('1-Tap Apply', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // CARD 1: Automated In-App Setup
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF38BDF8), size: 20),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Automated In-App Setup',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                                Text(
                                  'Zero typing: auto-extracts credentials & auto-closes browser',
                                  style: TextStyle(color: Colors.white60, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0284C7),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.rocket_launch_rounded, size: 18),
                          label: const Text(
                            'Launch In-App Web Assistant',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          onPressed: _isTestingCredentials ? null : _launchWebAssistant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // CARD 2: 1-Tap Auto-Paste from Clipboard
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF0A84FF), width: 1.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      backgroundColor: const Color(0xFF0A84FF).withValues(alpha: 0.08),
                    ),
                    icon: const Icon(Icons.content_paste_go_rounded, color: Color(0xFF0A84FF), size: 20),
                    label: const Text(
                      '📋 1-Tap Auto-Paste from Clipboard',
                      style: TextStyle(color: Color(0xFF0A84FF), fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    onPressed: _pasteFromClipboard,
                  ),
                ),
                const SizedBox(height: 24),

                // CARD 3: Manual Credentials (Empty by default)
                const Text(
                  'MANUAL CREDENTIALS',
                  style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8),
                ),
                const SizedBox(height: 12),

                // API ID
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('API ID (App ID)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                    TextButton.icon(
                      style: TextButton.styleFrom(visualDensity: VisualDensity.compact, padding: const EdgeInsets.symmetric(horizontal: 4)),
                      icon: const Icon(Icons.content_paste_rounded, size: 14, color: Color(0xFF0A84FF)),
                      label: const Text('Paste ID', style: TextStyle(color: Color(0xFF0A84FF), fontSize: 12)),
                      onPressed: () async {
                        final data = await Clipboard.getData(Clipboard.kTextPlain);
                        if (data?.text != null) {
                          final parsed = TelegramCredentialParser.parse(data!.text!);
                          _apiIdController.text = (parsed.apiId ?? int.tryParse(data.text!.trim()) ?? '').toString();
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _apiIdController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'e.g. 28910420',
                    hintStyle: TextStyle(color: Colors.grey.shade600),
                    filled: true,
                    fillColor: const Color(0xFF1C1C1E),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF0A84FF), width: 1.5),
                    ),
                    prefixIcon: const Icon(Icons.tag, color: Colors.grey),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Please enter your Telegram API ID';
                    if (int.tryParse(val.trim()) == null) return 'API ID must be a valid number';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // API HASH
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('API HASH', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                    TextButton.icon(
                      style: TextButton.styleFrom(visualDensity: VisualDensity.compact, padding: const EdgeInsets.symmetric(horizontal: 4)),
                      icon: const Icon(Icons.content_paste_rounded, size: 14, color: Color(0xFF0A84FF)),
                      label: const Text('Paste Hash', style: TextStyle(color: Color(0xFF0A84FF), fontSize: 12)),
                      onPressed: () async {
                        final data = await Clipboard.getData(Clipboard.kTextPlain);
                        if (data?.text != null) {
                          final parsed = TelegramCredentialParser.parse(data!.text!);
                          _apiHashController.text = parsed.apiHash ?? data.text!.trim();
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _apiHashController,
                  obscureText: _obscureHash,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'e.g. 8da85b0d5b1652522bc46057082da478',
                    hintStyle: TextStyle(color: Colors.grey.shade600),
                    filled: true,
                    fillColor: const Color(0xFF1C1C1E),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF0A84FF), width: 1.5),
                    ),
                    prefixIcon: const Icon(Icons.key, color: Colors.grey),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureHash ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                      onPressed: () => setState(() => _obscureHash = !_obscureHash),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Please enter your Telegram API Hash';
                    if (val.trim().length < 16) return 'API Hash is too short (usually 32 hex characters)';
                    return null;
                  },
                ),
                const SizedBox(height: 28),

                // Save & Proceed Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0A84FF),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _isTestingCredentials ? null : _onManualSubmit,
                    child: _isTestingCredentials
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                              const SizedBox(width: 12),
                              Text(_statusText ?? 'Testing credentials...', style: const TextStyle(color: Colors.white, fontSize: 14)),
                            ],
                          )
                        : const Text(
                            'Save & Continue to Step 2 →',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
